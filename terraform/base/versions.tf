terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "hughze-poc-ecs"
    key     = "poc-ecs/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}