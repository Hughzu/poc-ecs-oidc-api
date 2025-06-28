variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "poc-ecs"
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
  default = "Hughzu"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default = "poc-ecs-oidc-api"
}

variable "github_branches" {
  description = "List of GitHub branches that can assume the role"
  type        = list(string)
  default     = ["main", "develop"]
}