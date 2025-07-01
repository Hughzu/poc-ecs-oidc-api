provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

module "github_oidc_provider" {
  source = "./modules/github-oidc-provider"
  project_name = var.project_name
}

module "github-actions-role" {
  source = "./modules/github-actions-role"
  aws_region = var.aws_region
  project_name = var.project_name
  bucket_name = "hughze-poc-ecs"
  github_branches = ["main"]
  github_org = "Hughzu"
  github_repo = "poc-ecs-oidc-api"
  oidc_provider_arn = module.github_oidc_provider.oidc_provider_arn
}

module "budget" {
  source = "./modules/budget"
  project_name = var.project_name
  alert_email = "hughesstiernon@gmail.com"
  monthly_budget_limit = 50
}

