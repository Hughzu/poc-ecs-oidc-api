variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "ecr_repository_url" {
  description = "ECR repository URL for the application"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1  # Cost optimization
}

variable "cpu" {
  description = "CPU units for the task (1024 = 1 vCPU)"
  type        = number
  default     = 256  # Cost optimization
}

variable "memory" {
  description = "Memory for the task in MB"
  type        = number
  default     = 512  # Cost optimization
}

variable "log_retention_days" {
  description = "CloudWatch log retention period"
  type        = number
  default     = 7  # Cost optimization
}

variable "health_check_path" {
  description = "Health check path for ALB"
  type        = string
  default     = "/"
}

variable "enable_autoscaling" {
  description = "Enable auto scaling (set to false for cost optimization)"
  type        = bool
  default     = false  # Cost optimization
}

# EC2-specific variables
variable "instance_type" {
  description = "EC2 instance type for ECS instances"
  type        = string
  default     = "t3.micro"  # Cost optimization
}

variable "min_capacity" {
  description = "Minimum number of EC2 instances"
  type        = number
  default     = 1  # Cost optimization
}

variable "max_capacity" {
  description = "Maximum number of EC2 instances"
  type        = number
  default     = 2  # Cost optimization
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances"
  type        = number
  default     = 1  # Cost optimization
}