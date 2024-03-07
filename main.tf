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

locals {
  bucket_name            = var.bucket_name != null ? var.bucket_name : var.url
  normalized_bucket_name = replace(local.bucket_name, ".", "-")
}

resource "aws_s3_bucket" "this" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.this]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  count = var.versioning != "" ? 1 : 0

  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning
  }
}

module "source_code" {
  count = var.static_content_path != null ? 1 : 0

  source  = "hashicorp/dir/template"
  version = "~> 1.0"

  base_dir = var.static_content_path
}

resource "aws_s3_object" "this" {
  for_each = var.static_content_path != null ? module.source_code[0].files : {}

  bucket       = aws_s3_bucket.this.bucket
  key          = each.key
  source       = each.value.source_path
  content      = each.value.content
  content_type = each.value.content_type
  etag         = each.value.digests.md5
}

# Allow CloudFront to serve content from S3 through Origin Access Control policy
data "aws_iam_policy_document" "this" {
  statement {
    sid       = "AllowCloudFrontServicePrincipal"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Cache everything for 30 seconds. They are static files anyway
resource "aws_cloudfront_cache_policy" "this" {
  name        = "${local.normalized_bucket_name}-s3"
  default_ttl = var.cloudfront_cache_default_ttl
  max_ttl     = 86400 # 86400 = 1 day
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

resource "aws_cloudfront_origin_access_control" "this" {
  # Docs: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html
  name                              = local.normalized_bucket_name
  description                       = "Allow CloudFront to access S3 as origin following the recommended Origin Access Control design pattern."
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  aliases             = [var.url]
  comment             = "For static web site ${var.url}"
  default_root_object = var.index_page
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  wait_for_deployment = false

  origin {
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id                = "static"
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
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
      response_page_path    = "/${var.error_page}"
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
  count = var.route53_domain != null ? 1 : 0
  name  = var.route53_domain
}

resource "aws_route53_record" "this" {
  for_each = var.route53_domain != null ? toset(concat([var.url], var.cloudfront_additional_cnames)) : toset([])

  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = each.value
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

  create_route53_records    = var.route53_domain != null
  domain_name               = var.url
  zone_id                   = var.route53_domain != null ? data.aws_route53_zone.this[0].id : null
  subject_alternative_names = var.cloudfront_additional_cnames
}
