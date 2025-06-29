# AWS DevOps Project: Secure API Deployment with OIDC

## 🎯 Project Objectives

Deploy an API application to AWS ECS (EC2) in a private VPC through a fully automated CI/CD pipeline using passwordless authentication (OIDC), accessible from your local machine.

### Learning Goals
- **Terraform**: Infrastructure as Code for AWS resources
- **AWS Services**: VPC, ECS, EC2, ALB, IAM, ECR
- **GitHub Actions**: CI/CD pipeline automation
- **OIDC Security**: Passwordless authentication between GitHub and AWS
- **Container Orchestration**: ECS with EC2 instances
- **Network Security**: Private VPC with secure access patterns

## 📋 Prerequisites

- AWS Account with billing alerts configured
- GitHub account
- Local development environment with:
  - Terraform installed
  - AWS CLI installed
  - Docker installed
  - Git configured

## 🏗️ Architecture Overview

```
Internet → Internet Gateway → Public Subnet (ALB) → Private Subnet (ECS Tasks) → VPC Endpoints
```

**Key Components:**
- VPC with public/private subnets
- Application Load Balancer in public subnet
- ECS Cluster with EC2 instances in private subnet
- VPC Endpoints for AWS services (ECR, CloudWatch)
- GitHub Actions with OIDC for deployment
- Terraform for infrastructure provisioning

## 📅 Timeline

**Phase 1: Foundation Setup**
- [x] Create GitHub repository
- [x] Create dummy API with docker image
- [x] Set up basic project structure
- [x] Configure AWS OIDC Identity Provider
- [x] Create initial Terraform configuration (with backend store in S3)

**Phase 2: Infrastructure Development**
- [x] Develop VPC and networking resources
- [ ] Create ECS cluster and task definitions
- [ ] Set up Application Load Balancer
- [ ] Set up Security Groups (https only at least ...)
- [ ] Configure VPC endpoints

**Phase 3: Application & Pipeline**
- [x] Create sample API application
- [x] Build Docker container
- [x] Set up ECR repository
- [x] Develop GitHub Actions workflow

**Phase 4: Integration & Testing**
- [x] Deploy infrastructure via pipeline
- [ ] Test application deployment
- [ ] Verify security configurations
- [ ] Documentation and cleanup

## 🗂️ Project Structure

```
aws-ecs-project/
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml
│       └── terraform-apply.yml
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   └── modules/
│       ├── networking/
│       ├── ecs/
│       └── security/
├── app/
│   ├── Dockerfile
│   ├── app.py 
│   └── requirements.txt
├── scripts/
│   └── setup-oidc.sh
└── README.md
```

## ✅ Success Criteria

By Sunday evening, you should have:
- ✅ Fully automated infrastructure deployment via Terraform
- ✅ Passwordless CI/CD pipeline using OIDC
- ✅ Containerized API running on ECS with EC2
- ✅ Secure network architecture with private VPC
- ✅ Application accessible from your local machine
- ✅ Understanding of all technologies involved

## 💡 Next Steps

- Implement auto-scaling policies
- Add monitoring and alerting
- Set up blue/green deployments
- Implement service mesh (AWS App Mesh)
- Add database layer (RDS in private subnet)

---
