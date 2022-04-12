
##############################################
# Providers
##############################################

terraform {
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
