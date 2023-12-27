terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.0"
      configuration_aliases = [aws.us]
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "us"
}

locals {
  bucket_name            = var.bucket_name != null ? var.bucket_name : var.url
  normalized_bucket_name = replace(local.bucket_name, ".", "-")
}

resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
}

# data "aws_iam_policy_document" "this" {
#   statement {
#     sid       = "AllowCloudFrontServicePrincipal"
#     actions   = ["s3:GetObject"]
#     resources = ["${aws_s3_bucket.this.arn}/*"]

#     condition {
#       test     = "StringEquals"
#       variable = "AWS:SourceArn"
#       values   = [aws_cloudfront_distribution.this.arn]
#     }

#     principals {
#       type        = "Service"
#       identifiers = ["cloudfront.amazonaws.com"]
#     }
#   }
# }

# resource "aws_s3_bucket_policy" "this" {
#   bucket = aws_s3_bucket.this.id
#   policy = data.aws_iam_policy_document.this.json
# }

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Cache everything for 30 seconds. They are static files anyway
resource "aws_cloudfront_cache_policy" "this" {
  name        = "${local.normalized_bucket_name}-s3"
  default_ttl = var.cloudfront_cache_default_ttl
  max_ttl     = 86400 # 86300 = 1 day
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "Cloudfront access identity for ${local.bucket_name} S3 bucket."
}

resource "aws_cloudfront_distribution" "this" {
  aliases             = [var.url]
  comment             = ""
  default_root_object = var.index_page
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  wait_for_deployment = false

  origin {
    domain_name = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id   = "static"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "static"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = aws_cloudfront_cache_policy.this.id
  }

  viewer_certificate {
    acm_certificate_arn      = module.acm.acm_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  dynamic "custom_error_response" {
    for_each = toset(var.cloudfront_redirected_http_codes)
    content {
      error_caching_min_ttl = 60
      error_code            = custom_error_response.value
      response_code         = 200
      response_page_path    = "/${var.index_page}"
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  depends_on = [module.acm]
}

data "aws_route53_zone" "this" {
  name = var.route53_domain
}

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.url
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  providers = {
    aws = aws.us
  }

  domain_name               = var.route53_domain
  zone_id                   = data.aws_route53_zone.this.id
  subject_alternative_names = [var.url]
}
