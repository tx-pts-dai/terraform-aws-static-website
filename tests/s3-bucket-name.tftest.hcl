### Providers

mock_provider "aws" {}


### Variables

variables {
    url = "autolayout.ness-dev.tamedia.ch"
    route53_domain = "ness-dev.tamedia.ch"
    cloudfront_additional_cnames = ["autolayout-2.ness-dev.tamedia.ch"]
}

### Tests

run "s3_bucket_name_matches_url_if_not_specified" {
    command = plan

    providers = {
        aws = aws
        aws.us = aws
    }

    assert {
        condition = aws_s3_bucket.this.bucket == "autolayout.ness-dev.tamedia.ch"
        error_message = "Bucket name should match the URL if 'bucket_name' is not specified"
    }
}


run "s3_bucket_name_matches_variable" {
    command = plan

    variables {
        bucket_name = "mycustombucketname"
    }

    providers = {
        aws = aws
        aws.us = aws
    }

    assert {
        condition = aws_s3_bucket.this.bucket == "mycustombucketname"
        error_message = "Bucket name should match the 'bucket_name' if specified"
    }
}
