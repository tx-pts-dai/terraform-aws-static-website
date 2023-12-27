variable "url" {
  description = "URL where the application is going to be served on. CloudFront will be deployed and a DNS record pointing to it too"
  type        = string
}

variable "route53_domain" {
  description = "Route53 hosted zone domain where the DNS record should be created. This is used for TLS certificate validation too. TODO: allow for CloudFlare-managed DNS records"
  type        = string
}

variable "bucket_name" {
  description = "Name of the bucket that will store the static website files. It will be served by CloudFront. If not specified, it uses the 'url'."
  type        = string
  default     = null
}

variable "index_page" {
  description = "Index page that should be displayed as root. Defauls to `index.html`"
  type        = string
  default     = "index.html"
}


variable "cloudfront_redirected_http_codes" {
  description = "List of HTTP status codes that are meant to be redirected to the var.index_page"
  type        = list(string)
  default     = [403, 404]
}

variable "cloudfront_cache_default_ttl" {
  description = "Default TTL (in seconds) for objects stored in S3 that will be served through CloudFront."
  type        = number
  default     = 30
}
