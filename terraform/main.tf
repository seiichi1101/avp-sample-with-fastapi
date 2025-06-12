# Terraform Setting
terraform {
  required_version = ">= 1.9.5"
  required_providers {
    aws = {
      version = ">= 5.21.0"
      source  = "hashicorp/aws"
    }
  }
}

# Provider
provider "aws" {
  region = "ap-northeast-1"
}

data "aws_caller_identity" "current" {}
