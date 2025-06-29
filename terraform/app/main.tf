provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
    }
  }
}

module "vpc" {
  source = "./modules/VPC"

  project_name = var.project_name
  aws_region   = var.aws_region
  vpc_cidr     = "10.0.0.0/16"
}

module "ecr" {
  source = "./modules/ECR"

  project_name           = var.project_name
  app_name              = var.app_name
}