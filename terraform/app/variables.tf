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

variable "app_name" {
  description = "Name of the project"
  type        = string
  default     = "api"
}