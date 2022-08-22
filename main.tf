terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-west-2"
  profile = "dev"
}


module "website_s3_bucket" {
  source = "./modules/aws-s3-bucket"

  bucket_name = "web-players"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

