# output "cluster_id" {
#   description = "ID of the ECS cluster"
#   value       = aws_ecs_cluster.main.id
# }

# output "cluster_name" {
#   description = "Name of the ECS cluster"
#   value       = aws_ecs_cluster.main.name
# }

# output "cluster_arn" {
#   description = "ARN of the ECS cluster"
#   value       = aws_ecs_cluster.main.arn
# }

# output "service_name" {
#   description = "Name of the ECS service"
#   value       = aws_ecs_service.app.name
# }

# output "service_arn" {
#   description = "ARN of the ECS service"
#   value       = aws_ecs_service.app.id
# }

# output "task_definition_arn" {
#   description = "ARN of the task definition"
#   value       = aws_ecs_task_definition.app.arn
# }

# output "alb_dns_name" {
#   description = "DNS name of the load balancer"
#   value       = aws_lb.main.dns_name
# }

# output "alb_arn" {
#   description = "ARN of the load balancer"
#   value       = aws_lb.main.arn
# }

# output "alb_zone_id" {
#   description = "Zone ID of the load balancer"
#   value       = aws_lb.main.zone_id
# }

# output "target_group_arn" {
#   description = "ARN of the target group"
#   value       = aws_lb_target_group.app.arn
# }

# output "ecs_security_group_id" {
#   description = "ID of the ECS instances security group"
#   value       = aws_security_group.ecs_instances.id
# }

# output "alb_security_group_id" {
#   description = "ID of the ALB security group"
#   value       = aws_security_group.alb.id
# }

# output "cloudwatch_log_group_name" {
#   description = "Name of the CloudWatch log group"
#   value       = aws_cloudwatch_log_group.ecs_logs.name
# }

# output "application_url" {
#   description = "URL to access the application"
#   value       = "http://${aws_lb.main.dns_name}"
# }

# EC2-specific outputs
# output "autoscaling_group_name" {
#   description = "Name of the Auto Scaling Group"
#   value       = aws_autoscaling_group.ecs_asg.name
# }

# output "launch_template_id" {
#   description = "ID of the launch template"
#   value       = aws_launch_template.ecs_instance.id
# }

# output "capacity_provider_name" {
#   description = "Name of the ECS capacity provider"
#   value       = aws_ecs_capacity_provider.main.name
# }

# output "ecs_instance_security_group_id" {
#   description = "ID of the ECS instances security group"
#   value       = aws_security_group.ecs_instances.id
# }