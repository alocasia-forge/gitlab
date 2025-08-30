terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket         = "alocasia-gitlab-dev"
    key            = "infrastructure/terraform.tfstate"
    profile = "alocasia"
    region         = "eu-west-1"    
  }
}

provider "aws" {
  region = "eu-west-1"
    profile = "alocasia"
  default_tags {
    tags = local.default_tags
  }
}