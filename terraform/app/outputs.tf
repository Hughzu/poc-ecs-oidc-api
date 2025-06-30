# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

# ECR Outputs
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

# ECS Outputs
# output "ecs_cluster_name" {
#   description = "Name of the ECS cluster"
#   value       = module.ecs.cluster_name
# }

# output "ecs_service_name" {
#   description = "Name of the ECS service"
#   value       = module.ecs.service_name
# }

# output "alb_dns_name" {
#   description = "DNS name of the load balancer"
#   value       = module.ecs.alb_dns_name
# }

# output "application_url" {
#   description = "URL to access the application"
#   value       = module.ecs.application_url
# }

# output "cloudwatch_log_group" {
#   description = "CloudWatch log group for ECS logs"
#   value       = module.ecs.cloudwatch_log_group_name
# }