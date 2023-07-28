terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

module "apigw" {
  source  = "armorfret/apigw-lambda/aws"
  version = "0.7.1"

  source_bucket  = var.lambda_bucket
  source_version = var.lambda_version
  function_name  = "hookexporter_${var.data_bucket}"

  environment_variables = {
    S3_BUCKET = var.config_bucket
    S3_KEY    = "config.yaml"
  }

  access_policy_document = data.aws_iam_policy_document.lambda_perms.json

  hostname = var.hostname

  binary_media_types = [
    "*/*",
  ]
}

module "publish_user" {
  source         = "armorfret/s3-publish/aws"
  version        = "0.8.0"
  logging_bucket = var.logging_bucket
  publish_bucket = var.data_bucket
}

module "config_user" {
  source         = "armorfret/s3-publish/aws"
  version        = "0.8.0"
  logging_bucket = var.logging_bucket
  publish_bucket = var.config_bucket
  count          = var.config_bucket == var.data_bucket ? 0 : 1
}

data "aws_iam_policy_document" "lambda_perms" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = distinct([
      "arn:aws:s3:::${var.data_bucket}/*",
      "arn:aws:s3:::${var.data_bucket}",
      "arn:aws:s3:::${var.config_bucket}/*",
      "arn:aws:s3:::${var.config_bucket}",
    ])
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:*:log-group:/aws/lambda/hookexporter_${var.data_bucket}:*",
    ]
  }
}

