# AWS ECS Application Infrastructure Guide

This guide explains the application infrastructure deployed via `terraform/app`, focusing on how each AWS component works together to run a containerized FastAPI application on Amazon ECS with EC2 instances.

## 🎯 What You'll Deploy

- **VPC with Private/Public Subnets**: Secure network isolation
- **Application Load Balancer**: Internet-facing entry point
- **ECS Cluster with EC2 Instances**: Container orchestration platform
- **ECR Repository**: Private Docker image registry
- **Auto Scaling Group**: Dynamic instance management
- **CloudWatch Logs**: Centralized logging
- **Security Groups**: Network access control

## 🏗️ Architecture Overview

```
Internet → ALB (Public Subnet) → ECS Tasks (Private Subnet) → ECR/CloudWatch
```

The architecture follows AWS best practices with a clear separation between public-facing resources and private application components.

## 📋 Prerequisites

Before deploying the application infrastructure:

- ✅ **Common Infrastructure Deployed**: OIDC, IAM roles, and budget monitoring from `terraform/common`
- ✅ **GitHub Secrets Configured**: `AWS_ROLE_ARN` and `AWS_REGION` set in repository
- ✅ **Application Code Ready**: FastAPI application in the `app/` folder
- ✅ **Docker Image**: Built and ready to be pushed to ECR

## 🔧 Component Deep Dive

### 1. VPC (Virtual Private Cloud)
**Location**: `terraform/app/modules/vpc/main.tf`

The VPC provides the network foundation for all resources:

```hcl
# Core VPC with DNS support for ECS
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true  # Required for VPC endpoints
  enable_dns_support   = true  # Required for ECS to pull images
}
```

**Key Features:**
- **CIDR Block**: `10.0.0.0/16` provides 65,536 IP addresses
- **DNS Support**: Enables ECS tasks to resolve ECR endpoints
- **Multi-AZ**: Spans multiple availability zones for high availability

**Subnets Configuration:**
- **Public Subnets**: `10.0.1.0/24`, `10.0.2.0/24` (for ALB)
- **Private Subnets**: `10.0.10.0/24`, `10.0.11.0/24` (for ECS tasks)

### 2. Internet Gateway & NAT Gateway
**Purpose**: Provide internet connectivity with security

```hcl
# Internet Gateway for public subnet internet access
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Single NAT Gateway for cost optimization
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id  # Only in first public subnet
}
```

**Traffic Flow:**
1. **Inbound**: Internet → IGW → ALB (Public Subnet) → ECS (Private Subnet)
2. **Outbound**: ECS (Private Subnet) → NAT Gateway → IGW → Internet

**Cost Optimization**: Single NAT Gateway instead of one per AZ saves ~$45/month

### 3. Application Load Balancer (ALB)
**Location**: `terraform/app/modules/ecs/main.tf`

The ALB serves as the internet-facing entry point:

```hcl
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false  # Internet-facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids  # Deployed in public subnets
}
```

**Key Features:**
- **Layer 7 Load Balancing**: HTTP/HTTPS traffic distribution
- **Health Checks**: Monitors application health on `/` endpoint
- **Target Group**: Routes traffic to ECS tasks on dynamic ports
- **Security Group**: Allows HTTP (80) and HTTPS (443) from internet

**Traffic Routing:**
```
Internet (Port 80/443) → ALB → Target Group → ECS Tasks (Dynamic Ports 32768-65535)
```

### 4. ECR (Elastic Container Registry)
**Location**: `terraform/app/modules/ECR/main.tf`

Private Docker registry for storing application images:

```hcl
resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}/${var.app_name}"  # poc-ecs/api
  image_tag_mutability = "MUTABLE"
  force_delete         = true  # Allows deletion even with images
  
  image_scanning_configuration {
    scan_on_push = false  # Cost optimization
  }
}
```

**Lifecycle Policy**:
- **Tagged Images**: Keep only last 3 versions
- **Untagged Images**: Delete after 1 day
- **Purpose**: Automatic cleanup to control storage costs

**Integration**:
- **GitHub Actions**: Pushes images with tags like `latest`, `main-abc123`
- **ECS Tasks**: Pulls images during container startup

### 5. ECS Cluster & EC2 Infrastructure
**Location**: `terraform/app/modules/ecs/main.tf`

The heart of the container orchestration:

#### ECS Cluster
```hcl
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
  setting {
    name  = "containerInsights"
    value = "disabled"  # Cost optimization
  }
}
```

#### EC2 Auto Scaling Group
```hcl
resource "aws_autoscaling_group" "ecs_asg" {
  name                      = "${var.project_name}-ecs-asg"
  vpc_zone_identifier       = var.private_subnet_ids  # Deployed in private subnets
  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  
  min_size         = var.min_capacity     # Default: 1
  max_size         = var.max_capacity     # Default: 2
  desired_capacity = var.desired_capacity # Default: 1
  
  launch_template {
    id      = aws_launch_template.ecs_instance.id
    version = "$Latest"
  }
}
```

**Instance Configuration**:
- **Instance Type**: `t3.micro` (1 vCPU, 1GB RAM) - Cost optimized
- **AMI**: Amazon ECS-optimized AMI (automatically fetched latest)
- **User Data**: Registers instances with ECS cluster
- **IAM Role**: Allows ECS agent to communicate with ECS service

#### ECS Capacity Provider
```hcl
resource "aws_ecs_capacity_provider" "main" {
  name = "${var.project_name}-capacity-provider"
  
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_asg.arn
    managed_termination_protection = "DISABLED" # Cost optimization
    
    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 2
    }
  }
}
```

**Purpose**: Automatically manages EC2 instances based on ECS task demand

### 6. ECS Task Definition & Service
**Location**: `terraform/app/modules/ecs/main.tf`

Defines how containers run:

#### Task Definition
```hcl
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-${var.app_name}"
  network_mode             = "bridge"  # Required for EC2 launch type
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  
  container_definitions = jsonencode([{
    name  = var.app_name
    image = "${var.ecr_repository_url}:latest"
    cpu   = var.cpu    # Default: 256 (0.25 vCPU)
    memory = var.memory # Default: 512 MB
    
    portMappings = [{
      containerPort = var.container_port  # Default: 8000
      protocol      = "tcp"
    }]
    
    # Built-in health check
    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}${var.health_check_path} || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 0
    }
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "ecs"
      }
    }
    
    essential = true
  }])
}
```

#### ECS Service
```hcl
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-${var.app_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count  # Default: 1
  launch_type     = "EC2"
  
  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.app_name
    container_port   = var.container_port
  }
  
  lifecycle {
    ignore_changes = [desired_count]  # Allows manual scaling
  }
}
```

**Key Features**:
- **Desired Count**: Maintains 1 running task
- **Load Balancer Integration**: Registers tasks with ALB target group
- **Health Checks**: ECS monitors task health and replaces failed tasks
- **Automatic Registration**: Tasks automatically register/deregister with ALB

### 7. Security Groups
**Location**: `terraform/app/modules/ecs/main.tf`

Network security through firewall rules:

#### ALB Security Group
```hcl
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  vpc_id      = var.vpc_id
  
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP from internet
  }
  
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTPS from internet
  }
}
```

#### ECS Security Group
```hcl
resource "aws_security_group" "ecs_instances" {
  name_prefix = "${var.project_name}-ecs-instances-"
  vpc_id      = var.vpc_id
  
  ingress {
    description     = "Dynamic ports from ALB"
    from_port       = 32768
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]  # Only from ALB
  }
  
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Only from within VPC
  }
}
```

**Security Model**:
- **ALB**: Accepts traffic from internet on ports 80/443
- **ECS**: Only accepts traffic from ALB on dynamic ports (32768-65535)
- **SSH Access**: Limited to VPC CIDR range for debugging
- **Egress**: Both allow all outbound traffic for downloads/updates

### 8. CloudWatch Logs
**Location**: `terraform/app/modules/ecs/main.tf`

Centralized logging for application monitoring:

```hcl
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_name}/${var.app_name}"
  retention_in_days = var.log_retention_days  # Default: 7 days
}
```

**Integration**:
- **ECS Tasks**: Automatically send stdout/stderr to CloudWatch
- **Log Streams**: Each task creates its own log stream
- **Retention**: 7 days to control costs

## 🚀 Deployment Process

### Step 1: Update Configuration
Update variables in `terraform/app/variables.tf`:

```hcl
variable "project_name" {
  default = "poc-ecs"  # Must match common infrastructure
}

variable "app_name" {
  default = "api"  # Your application name
}

variable "aws_region" {
  default = "eu-central-1"
}
```

### Step 2: Initialize Backend
Update the S3 backend in `terraform/app/versions.tf`:

```hcl
backend "s3" {
  bucket  = "hughze-poc-ecs"  # Same as common infrastructure
  key     = "app/terraform.tfstate"
  region  = "eu-central-1"
  encrypt = true
}
```

### Step 3: Deploy Infrastructure
```bash
cd terraform/app

# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

**Expected Output**:
```
Apply complete! Resources: 25+ added, 0 changed, 0 destroyed.

Outputs:
alb_dns_name = "poc-ecs-alb-123456789.eu-central-1.elb.amazonaws.com"
application_url = "http://poc-ecs-alb-123456789.eu-central-1.elb.amazonaws.com"
ecr_repository_url = "123456789012.dkr.ecr.eu-central-1.amazonaws.com/poc-ecs/api"
ecs_cluster_name = "poc-ecs-cluster"
ecs_service_name = "poc-ecs-api-service"
cloudwatch_log_group = "/ecs/poc-ecs/api"
```

### Step 4: Build and Deploy Application
The GitHub Actions workflow in `.github/workflows/docker-build-push.yml` will:

1. **Build Docker Image**: From `app/Dockerfile` using multi-stage build
2. **Push to ECR**: Tag with `latest` and commit SHA
3. **Update ECS Service**: Trigger new deployment with `force-new-deployment`
4. **Health Check**: ALB verifies application health

## 🔄 Component Interactions

### Application Startup Flow
1. **ECS Service** requests new task from **Task Definition**
2. **ECS Agent** on **EC2 Instance** pulls image from **ECR**
3. **Container** starts and binds to dynamic port (e.g., 32768)
4. **ECS Agent** registers container with **ALB Target Group**
5. **ALB** starts health checking container on `/` endpoint
6. **Container logs** stream to **CloudWatch Logs**
7. **Health check** passes and ALB begins routing traffic

### Request Flow
1. **User** makes HTTP request to ALB DNS name
2. **ALB** receives request on port 80/443
3. **ALB** forwards request to healthy ECS task on dynamic port
4. **ECS Task** (FastAPI) processes request and returns response
5. **ALB** returns response to user

### Scaling Flow
1. **ECS Service** requests more tasks due to capacity needs
2. **Capacity Provider** evaluates **Auto Scaling Group** capacity
3. If needed, **ASG** launches new **EC2 Instance** using **Launch Template**
4. **New Instance** registers with **ECS Cluster** via user data script
5. **ECS Service** places additional tasks on new capacity
6. **Tasks** automatically register with **ALB Target Group**


## 🔧 Cost Optimization Features

- **Single NAT Gateway**: ~$45/month savings vs multi-AZ
- **t3.micro Instances**: Smallest viable instance type (~$8.50/month)
- **Disabled Container Insights**: Saves CloudWatch costs
- **7-day Log Retention**: Reduces log storage costs
- **ECR Lifecycle Policy**: Automatic image cleanup
- **Force Delete ECR**: Easy cleanup during development
- **No VPC Endpoints**: Traffic goes through NAT (acceptable for small apps)
- **Disabled Detailed Monitoring**: Saves CloudWatch metric costs

## 🎯 Success Criteria

After successful deployment, you should have:

- ✅ **Working Application**: Accessible via ALB DNS name
- ✅ **Container Orchestration**: ECS managing application lifecycle
- ✅ **Auto Scaling**: Infrastructure scales based on demand
- ✅ **Centralized Logging**: Application logs in CloudWatch
- ✅ **Secure Network**: Private subnet isolation with controlled access
- ✅ **Health Monitoring**: ALB health checks ensuring availability
- ✅ **Automated Deployments**: GitHub Actions CI/CD pipeline

## 🚀 Testing Your Deployment

### Access Your Application
Visit the ALB DNS name from the Terraform output:
```bash
curl http://your-alb-dns-name.elb.amazonaws.com/
# Expected: {"message": "Hello my man"}

curl http://your-alb-dns-name.elb.amazonaws.com/hello/world
# Expected: {"message": "Hello world"}
```

## 🚀 Next Steps

1. **Add Custom Domain**: Route 53 + ACM for HTTPS
2. **Implement Auto Scaling**: CPU/Memory-based scaling policies
3. **Add Database**: RDS in private subnet
4. **Enhanced Monitoring**: CloudWatch alarms and dashboards
5. **Blue/Green Deployment**: CodeDeploy integration
6. **Service Mesh**: AWS App Mesh for microservices
7. **Secrets Management**: AWS Secrets Manager for sensitive data