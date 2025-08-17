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
    region         = "eu-west-1"    
  }
}

provider "aws" {
  region = "eu-west-1"
}