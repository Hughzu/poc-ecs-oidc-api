provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
    }
  }
}

module "ecr" {
  source = "./modules/ecr"

  project_name           = var.project_name
  app_name              = var.app_name
}