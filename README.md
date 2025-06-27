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
- [ ] Create GitHub repository
- [ ] Create dummy API with docker image
- [ ] Set up basic project structure
- [ ] Configure AWS OIDC Identity Provider
- [ ] Create initial Terraform configuration (with backend store in S3)

**Phase 2: Infrastructure Development**
- [ ] Develop VPC and networking resources
- [ ] Create ECS cluster and task definitions
- [ ] Set up Application Load Balancer
- [ ] Configure VPC endpoints

**Phase 3: Application & Pipeline**
- [ ] Create sample API application
- [ ] Build Docker container
- [ ] Set up ECR repository
- [ ] Develop GitHub Actions workflow

**Phase 4: Integration & Testing**
- [ ] Deploy infrastructure via pipeline
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

## 👤 AWS Account Setup & Least Privilege

### Option 1: Dedicated AWS Account (Recommended)
**Best for learning and isolation**
- Create a new AWS account specifically for this project
- Use AWS Organizations to manage if you have other accounts
- Benefits:
  - Complete isolation from production resources
  - No risk of interfering with existing infrastructure
  - Easy cost tracking and cleanup
  - Full control over IAM policies

### Security Boundaries
- **Resource Tagging**: Tag all resources with `Project: weekend-ecs`
- **Region Restriction**: Limit to specific region (e.g., us-east-1)
- **Cost Alerts**: Set up billing alerts for $50+ charges
- **Time-bound**: Role sessions limited to 1 hour max

### Recommended Setup Flow
1. **Create dedicated AWS account** OR **create IAM user with bootstrap permissions**
2. **Set up OIDC provider** manually (one-time setup)
3. **Create GitHub Actions role** with least privilege
4. **Delete bootstrap user** (if using Option 2)
5. **All subsequent operations** happen via OIDC role

## 🔒 Security Considerations

- **No hardcoded credentials** - All authentication via OIDC
- **Private subnets** for application workloads
- **Security groups** with minimal required access
- **VPC Endpoints** to avoid internet routing for AWS services
- **IAM roles** with least privilege principle
- **ECR repository** with vulnerability scanning enabled

## 📊 Monitoring and Observability

- **CloudWatch** for application and infrastructure logs
- **ECS Service** metrics and alarms
- **Application Load Balancer** access logs
- **VPC Flow Logs** for network monitoring

## 🚨 Troubleshooting Guide

### Common Issues:
1. **OIDC Authentication Failures**
   - Verify GitHub repository path in trust policy
   - Check OIDC provider configuration

2. **ECS Task Startup Issues**
   - Review CloudWatch logs
   - Verify ECR image availability
   - Check security group rules

3. **Application Access Issues**
   - Verify ALB target group health
   - Check route table configurations
   - Validate security group rules

## 🧹 Cleanup Procedure

1. **Destroy Infrastructure**
   ```bash
   terraform destroy -auto-approve
   ```

2. **Remove OIDC Provider** (if desired)
3. **Delete ECR Images** (to avoid charges)
4. **Archive GitHub Repository**

## 📚 Learning Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)

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
