terraform {
  required_version = "~> 1.5"

  backend "local" {
    path = "./minimal.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {}
provider "aws" {
  region = "us-east-1"
  alias  = "us"
}

module "frontend_complete" {
  source = "../"

  url                          = "autolayout.ness-dev.tamedia.ch"
  route53_domain               = "ness-dev.tamedia.ch"
  cloudfront_additional_cnames = ["autolayout-2.ness-dev.tamedia.ch"]

  # Optional
  static_content_path = "./build/"
  versioning          = "Enabled"

  providers = {
    aws.us = aws.us
  }
}

module "frontend" {
  source = "../"

  url            = "autolayout.ness-dev.tamedia.ch"
  route53_domain = "ness-dev.tamedia.ch"

  # Optional
  static_content_path = "./build/"

  providers = {
    aws.us = aws.us
  }
}

module "frontend_no_files" {
  source = "../"

  url            = "autolayout.ness-dev.tamedia.ch"
  route53_domain = "ness-dev.tamedia.ch"

  providers = {
    aws.us = aws.us
  }
}

module "frontend_no_dns" {
  source = "../"

  url = "autolayout.ness-dev.tamedia.ch"

  providers = {
    aws.us = aws.us
  }
}
