# TLS certificate ARN
output "acm_certificate_arn" {
  description = "ARN of the TLS certificate created and configured on the custom domain for the CloudFront distribution."
  value       = module.acm.acm_certificate_arn
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution that serves the content."
  value       = aws_cloudfront_distribution.this.id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution that serves the content."
  value       = aws_cloudfront_distribution.this.arn
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution that serves the content."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket that hosts the static website files."
  value       = aws_s3_bucket.this.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket that hosts the static website files."
  value       = aws_s3_bucket.this.arn
}
