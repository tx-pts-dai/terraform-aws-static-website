# AWS Static Website (CloudFront+S3+Route53)

Terraform module to host a static website on AWS by exploiting the basics: CloudFront, S3, ACM and Route53.

## Usage

```hcl
# Required for TLS Certificate for CloudFront distribution
provider "aws" {
  region = "us-east-1"
  alias = "us"
}

module "frontend" {
  source = "github.com/tx-pts-dai/terraform-aws-static-website"

  providers = {
    aws.us = aws.us
  }

  url            = "autolayout.ness-dev.tamedia.ch"
  route53_domain = "ness-dev.tamedia.ch"

  # Optional
  static_content_path = "./build/"
}

```

## Explanation and description of interesting use-cases

This module shall be used when you want to host a static website with low friction, simply by setting 3 parameters. Built-in you'll find the most common setup with Cloudfront, S3, Route53.

It offers the following features:

- Default caching on all the static files (make sure to name them uniquely to allow for automatic cache invalidation mechanism)
- Auto-upload static files to S3
- Create and manage TLS certificate and DNS record for a custom domain (Route53)

## Examples

< if the folder `examples/` exists, put here the link to the examples subfolders with their descriptions >

### Pre-Commit

Installation: [install pre-commit](https://pre-commit.com/) and execute `pre-commit install`. This will generate pre-commit hooks according to the config in `.pre-commit-config.yaml`

Before submitting a PR be sure to have used the pre-commit hooks or run: `pre-commit run -a`

The `pre-commit` command will run:

- Terraform fmt
- Terraform validate
- Terraform docs
- Terraform validate with tflint
- check for merge conflicts
- fix end of files

as described in the `.pre-commit-config.yaml` file

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm"></a> [acm](#module\_acm) | terraform-aws-modules/acm/aws | ~> 4.0 |
| <a name="module_source_code"></a> [source\_code](#module\_source\_code) | hashicorp/dir/template | ~> 1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_cache_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_cache_policy) | resource |
| [aws_cloudfront_distribution.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_origin_access_control.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | resource |
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_object.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the bucket that will store the static website files. It will be served by CloudFront. If not specified, it uses the 'url'. | `string` | `null` | no |
| <a name="input_cloudfront_additional_cnames"></a> [cloudfront\_additional\_cnames](#input\_cloudfront\_additional\_cnames) | List of Altername names to use for the CloudFront distribution | `list(string)` | `[]` | no |
| <a name="input_cloudfront_cache_default_ttl"></a> [cloudfront\_cache\_default\_ttl](#input\_cloudfront\_cache\_default\_ttl) | Default TTL (in seconds) for objects stored in S3 that will be served through CloudFront. | `number` | `30` | no |
| <a name="input_cloudfront_redirected_http_codes"></a> [cloudfront\_redirected\_http\_codes](#input\_cloudfront\_redirected\_http\_codes) | List of HTTP status codes that are meant to be redirected to the var.index\_page | `list(string)` | <pre>[<br>  403,<br>  404<br>]</pre> | no |
| <a name="input_error_page"></a> [error\_page](#input\_error\_page) | Error page that should be displayed whenever CloudFront returns any of the 'var.cloudfront\_redirected\_http\_codes'. Defauls to `index.html` | `string` | `"index.html"` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Set this to true, apply and then you are able to force destroy all the resources in the cluster. | `bool` | `false` | no |
| <a name="input_index_page"></a> [index\_page](#input\_index\_page) | Index page that should be displayed as root. Defauls to `index.html` | `string` | `"index.html"` | no |
| <a name="input_route53_domain"></a> [route53\_domain](#input\_route53\_domain) | Route53 hosted zone domain where the DNS record should be created. This is used for TLS certificate validation too. If 'null' then skip it. | `string` | `null` | no |
| <a name="input_static_content_path"></a> [static\_content\_path](#input\_static\_content\_path) | Path to the website static files to be uploaded to S3. If 'null', no objects are uploaded and app deployment can be handled separately. | `string` | `null` | no |
| <a name="input_url"></a> [url](#input\_url) | URL where the application is going to be served on. CloudFront will be deployed and a DNS record pointing to it too | `string` | n/a | yes |
| <a name="input_versioning"></a> [versioning](#input\_versioning) | Bucket versioning. Either "", "Enabled", "Suspended" of "Disabled" | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_acm_certificate_arn"></a> [acm\_certificate\_arn](#output\_acm\_certificate\_arn) | ARN of the TLS certificate created and configured on the custom domain for the CloudFront distribution. |
| <a name="output_cloudfront_distribution_arn"></a> [cloudfront\_distribution\_arn](#output\_cloudfront\_distribution\_arn) | ARN of the CloudFront distribution that serves the content. |
| <a name="output_cloudfront_distribution_domain_name"></a> [cloudfront\_distribution\_domain\_name](#output\_cloudfront\_distribution\_domain\_name) | Domain name of the CloudFront distribution that serves the content. |
| <a name="output_cloudfront_distribution_id"></a> [cloudfront\_distribution\_id](#output\_cloudfront\_distribution\_id) | ID of the CloudFront distribution that serves the content. |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | ARN of the S3 bucket that hosts the static website files. |
| <a name="output_s3_bucket_name"></a> [s3\_bucket\_name](#output\_s3\_bucket\_name) | Name of the S3 bucket that hosts the static website files. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module is maintained by [Alfredo Gottardo](https://github.com/AlfGot), [David Beauvererd](https://github.com/Davidoutz), [Davide Cammarata](https://github.com/DCamma), [Demetrio Carrara](https://github.com/sgametrio) and [Roland Bapst](https://github.com/rbapst-tamedia)

## License

Apache 2 Licensed. See [LICENSE](< link to license file >) for full details.
