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
  source = "./modules/vpc"

  project_name = var.project_name
  aws_region   = var.aws_region
  vpc_cidr     = "10.0.0.0/16"
}

module "ecr" {
  source = "./modules/ECR"

  project_name           = var.project_name
  app_name              = var.app_name
}

# module "ecs" {
#   source = "./modules/ecs"

#   project_name        = var.project_name
#   app_name           = var.app_name
#   vpc_id             = module.vpc.vpc_id
#   private_subnet_ids = module.vpc.private_subnet_ids
#   public_subnet_ids  = module.vpc.public_subnet_ids
#   ecr_repository_url = module.ecr.repository_url

#   # Cost optimization settings
#   desired_count     = 1
#   cpu              = 256
#   memory           = 512
#   enable_autoscaling = false
#   log_retention_days = 7

#   # EC2-specific settings
#   instance_type    = "t3.micro"  # Cost optimization
#   min_capacity     = 1
#   max_capacity     = 2
#   desired_capacity = 1

#   # Application settings
#   container_port    = 8000
#   health_check_path = "/"
# }