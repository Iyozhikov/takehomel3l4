
terraform {
  # backend "s3" {
  #     bucket         = "takehomel3l4"      # the name of the S3 bucket to keep states
  #     encrypt        = true
  #     key            = "/users/igor"       # the path to the terraform.tfstate file
  #     region         = "us-west-2"         # the location of the bucket
  #     dynamodb_table = "takehomel3l4-lock" # the name of the table to store the lock

  # }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = "us-west-2"
  profile = "takehome-1"
  version = "~> 3.0"
  default_tags {
    tags = {
      Environment = "TakeHome L3/L4"
    }
  }
}

data "aws_region" "current" {}