terraform {
  required_version = "1.12.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "979237820795-terraform"
    key     = "todo-app/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  default_tags {
    tags = {
      Environment = "Test"
      Name        = "myapp"
    }
  }

  region = var.aws_region
}
