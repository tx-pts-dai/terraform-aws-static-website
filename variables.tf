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

variable "error_page" {
  description = "Error page that should be displayed whenever CloudFront returns any of the 'var.cloudfront_redirected_http_codes'. Defauls to `index.html`"
  type        = string
  default     = "index.html"
}

variable "static_content_path" {
  description = "Path to the website static files to be uploaded to S3. If 'null', no objects are uploaded and app deployment can be handled separately."
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Set this to true, apply and then you are able to force destroy all the resources in the cluster."
  type        = bool
  default     = false
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
