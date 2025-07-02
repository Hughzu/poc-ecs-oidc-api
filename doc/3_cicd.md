# GitHub Actions CI/CD Pipeline Guide

This guide explains the complete CI/CD pipeline using GitHub Actions for your AWS ECS application, covering infrastructure deployment, Docker image building, and application deployment workflows.

## 🎯 What You'll Achieve

- **Passwordless CI/CD**: Secure OIDC authentication to AWS
- **Infrastructure as Code**: Automated Terraform deployments
- **Container Pipeline**: Automated Docker builds and pushes to ECR
- **Application Deployment**: Automatic ECS service updates
- **Cost Management**: Automated shutdown workflows for development
- **Full Automation**: Push-to-deploy workflow for rapid development

## 📋 Prerequisites

Before setting up the CI/CD pipeline:

- ✅ **OIDC Configuration**: Common infrastructure with GitHub OIDC provider deployed
- ✅ **GitHub Secrets**: `AWS_ROLE_ARN` and `AWS_REGION` configured in repository
- ✅ **Repository Structure**: Terraform code in `terraform/` and application in `app/`
- ✅ **ECR Repository**: Created through infrastructure deployment
- ✅ **ECS Cluster**: Deployed and ready to receive deployments

## 🏗️ CI/CD Architecture Overview

```
Developer Push → GitHub Actions → AWS (via OIDC) → Infrastructure/Application Updates
```

The CI/CD pipeline consists of multiple workflows that work together:

1. **Infrastructure Pipeline**: Deploys AWS resources via Terraform
2. **Docker Pipeline**: Builds and pushes container images
3. **Testing Pipeline**: Validates OIDC connections
4. **Shutdown Pipeline**: Cost optimization for development environments

## 🔧 Workflow Deep Dive

### 1. Infrastructure Deployment Workflow
**File**: `.github/workflows/terraform-infrastructure.yml`

This workflow manages the complete infrastructure lifecycle using Terraform.

#### Trigger Conditions
```yaml
on:
  push:
    branches: [main]
    paths:
      - 'terraform/app/**'
      - '.github/workflows/terraform-infrastructure.yml'
  workflow_dispatch:
    inputs:
      action:
        description: 'Terraform action to perform'
        required: true
        default: 'plan'
        type: choice
        options:
          - plan
          - apply
          - destroy
```

**Automatic Triggers**:
- **Push to main**: When Terraform files in `terraform/app/` change
- **Workflow file changes**: When the infrastructure workflow itself is modified

**Manual Triggers**:
- **Plan**: Review infrastructure changes without applying
- **Apply**: Manually deploy infrastructure changes
- **Destroy**: Tear down infrastructure (useful for cost management)

#### Key Workflow Steps

**Step 1: Environment Setup**
```yaml
- name: Setup Terraform
  uses: hashicorp/setup-terraform@v3
  with:
    terraform_version: ~1.0
    terraform_wrapper: false  # Prevents JSON parsing issues

- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    role-session-name: GitHubActions-Terraform-${{ github.run_number }}
    aws-region: ${{ secrets.AWS_REGION }}
```

**Step 2: Terraform Validation**
```yaml
- name: Terraform Format Check
  run: terraform fmt -check -recursive
  continue-on-error: true  # Don't fail build, just warn

- name: Terraform Init
  run: terraform init

- name: Terraform Validate
  run: terraform validate
```

**Step 3: Smart Planning with Exit Codes**
```yaml
- name: Terraform Plan
  run: |
    set +e  # Don't exit on non-zero exit codes
    terraform plan -detailed-exitcode -no-color -out=tfplan
    PLAN_EXIT_CODE=$?
    set -e  # Re-enable exit on error
    
    if [ $PLAN_EXIT_CODE -eq 0 ]; then
      echo "✅ No changes needed"
      echo "has_changes=false" >> $GITHUB_OUTPUT
    elif [ $PLAN_EXIT_CODE -eq 2 ]; then
      echo "📋 Changes detected, ready to apply"
      echo "has_changes=true" >> $GITHUB_OUTPUT
    else
      echo "❌ Plan failed"
      exit 1
    fi
```

**Terraform Exit Codes**:
- `0`: Success, no changes
- `1`: Error occurred
- `2`: Success, changes detected

**Step 4: Conditional Apply**
```yaml
- name: Terraform Apply (Auto on Push to Main)
  if: github.ref == 'refs/heads/main' && github.event_name == 'push' && steps.plan.outputs.has_changes == 'true'
  run: |
    terraform apply tfplan
    echo "✅ Infrastructure deployed successfully!"
```

**Logic**:
- **Automatic Apply**: Only on push to main branch with detected changes
- **Manual Apply**: Via workflow_dispatch with 'apply' action
- **Safety**: Never applies without a successful plan

**Step 5: Output Capture and Artifact Storage**
```yaml
- name: Output Infrastructure Details
  run: |
    terraform output -json > infrastructure-outputs.json
    echo "🏗️ Key Infrastructure Components:"
    echo "- VPC ID: $(terraform output -raw vpc_id 2>/dev/null || echo 'Not available')"
    echo "- ECS Cluster: $(terraform output -raw ecs_cluster_name 2>/dev/null || echo 'Not available')"
    echo "- ECR Repository: $(terraform output -raw ecr_repository_url 2>/dev/null || echo 'Not available')"
    echo "- Load Balancer DNS: $(terraform output -raw alb_dns_name 2>/dev/null || echo 'Not available')"

- name: Save Infrastructure Outputs
  uses: actions/upload-artifact@v4
  with:
    name: infrastructure-outputs-${{ github.run_number }}
    path: terraform/app/infrastructure-outputs.json
    retention-days: 30
```

**Purpose**: Captures Terraform outputs for use in other workflows or manual reference.

### 2. Docker Build and Push Workflow
**File**: `.github/workflows/docker-build-push.yml`

This workflow builds your application container and pushes it to ECR.

#### Trigger Conditions
```yaml
on:
  push:
    branches: [main]
    paths:
      - 'app/**'
      - '.github/workflows/docker-build-push.yml'
  workflow_dispatch:
```

**Triggers**:
- **Application Changes**: Any file in `app/` directory
- **Workflow Changes**: Updates to the Docker workflow itself
- **Manual Trigger**: For testing or emergency deployments

#### Environment Variables
```yaml
env:
  AWS_REGION: eu-central-1
  ECR_REPOSITORY: poc-ecs/api
  PROJECT_NAME: poc-ecs
  APP_NAME: api
```

#### Key Workflow Steps

**Step 1: ECR Authentication**
```yaml
- name: Login to Amazon ECR
  id: login-ecr
  uses: aws-actions/amazon-ecr-login@v2
```

**Step 2: Docker Metadata Extraction**
```yaml
- name: Extract metadata for Docker
  id: meta
  uses: docker/metadata-action@v5
  with:
    images: ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}
    tags: |
      type=ref,event=branch          # main
      type=ref,event=pr              # pr-123
      type=sha,prefix={{branch}}-    # main-abc1234
      type=raw,value=latest,enable={{is_default_branch}}  # latest (main only)
```

**Generated Tags**:
- `latest`: For main branch only
- `main`: Branch name
- `main-abc1234`: Branch + commit SHA
- `pr-123`: For pull requests

**Step 3: Optimized Docker Build**
```yaml
- name: Build and push Docker image
  uses: docker/build-push-action@v5
  with:
    context: ./app
    file: ./app/Dockerfile
    push: true
    tags: ${{ steps.meta.outputs.tags }}
    labels: ${{ steps.meta.outputs.labels }}
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

**Features**:
- **GitHub Actions Cache**: Speeds up builds by caching layers
- **Multi-platform**: Can be extended for ARM64 support
- **BuildKit**: Uses Docker BuildKit for improved performance

**Step 4: ECR Verification**
```yaml
- name: Verify image in ECR
  run: |
    aws ecr describe-images \
      --repository-name ${{ env.ECR_REPOSITORY }} \
      --region ${{ env.AWS_REGION }} \
      --output table \
      --query 'imageDetails[0:5].[imageTags[0],imagePushedAt,imageSizeInBytes]'
```

**Step 5: ECS Service Update**
```yaml
- name: Update ECS Service
  run: |
    aws ecs update-service \
      --cluster "${{ env.PROJECT_NAME }}-cluster" \
      --service "${{ env.PROJECT_NAME }}-${{ env.APP_NAME }}-service" \
      --force-new-deployment
```

**Deployment Process**:
1. **Force New Deployment**: Triggers ECS to pull latest image
2. **Rolling Update**: ECS gradually replaces old tasks with new ones
3. **Health Check**: ALB verifies new tasks are healthy before routing traffic
4. **Rollback**: ECS can automatically rollback if health checks fail

### 3. OIDC Testing Workflow
**File**: `.github/workflows/test-oidc.yml`

Simple workflow to validate OIDC authentication is working correctly.

```yaml
- name: Test AWS Access - Get Caller Identity
  run: |
    echo "Testing AWS CLI access..."
    aws sts get-caller-identity
    echo "✅ OIDC connection successful!"
```

**Purpose**:
- **Validation**: Confirms OIDC setup is working
- **Debugging**: Helps troubleshoot authentication issues
- **Manual Testing**: Can be triggered manually for verification

### 4. Cost Optimization Shutdown Workflow
**File**: `.github/workflows/evening-shutdown.yml`

Automated infrastructure shutdown for development cost management.

#### Scheduled Shutdown
```yaml
on: 
  schedule:
    - cron: '0 23 * * 0-6'  # 11 PM daily (UTC)
  workflow_dispatch:  # Manual trigger
```

**Schedule**: Runs at 23:00 UTC (11 PM) every day of the week.

#### Quick Destruction Process
```yaml
- name: Quick shutdown
  run: |
    echo "⚡ QUICK SHUTDOWN INITIATED"
    echo "🔧 Initializing Terraform..."
    terraform init
    
    echo "🔍 Checking for resources..."
    if terraform state list | grep -q .; then
      echo "✅ Resources found, proceeding with destruction"
      terraform destroy -auto-approve
      echo "✅ Quick shutdown completed!"
    else
      echo "ℹ️ No resources found to destroy"
    fi
```

**Safety Features**:
- **State Check**: Only destroys if resources exist
- **Auto-approve**: No manual confirmation needed
- **Logging**: Clear progress indicators

## 🔄 Complete CI/CD Flow

### Development Flow
1. **Developer pushes code** to `main` branch
2. **Infrastructure workflow** checks for Terraform changes
   - If changes detected: Runs `terraform plan` and `terraform apply`
   - Updates AWS infrastructure automatically
3. **Docker workflow** checks for application changes
   - If changes detected: Builds new Docker image
   - Pushes image to ECR with multiple tags
   - Triggers ECS service update
4. **ECS rolling deployment** occurs
   - Pulls new image from ECR
   - Starts new tasks with updated code
   - Performs health checks via ALB
   - Routes traffic to healthy tasks
   - Terminates old tasks

### Manual Operations Flow
```yaml
# Manual infrastructure deployment
workflow_dispatch:
  inputs:
    action: 'apply'  # or 'plan' or 'destroy'

# Manual Docker build
workflow_dispatch: {}

# Manual shutdown
workflow_dispatch: {}
```

## 🛡️ Security Features

### OIDC Security
```yaml
permissions:
  id-token: write   # Required for OIDC
  contents: read    # Required for checkout
```

**Benefits**:
- **No Long-lived Credentials**: No AWS keys stored in GitHub
- **Automatic Rotation**: Tokens are short-lived and automatically renewed
- **Conditional Access**: Only specific branches can assume the role
- **Audit Trail**: All actions logged in AWS CloudTrail

### Secure Variable Management
```yaml
# Using GitHub Secrets
role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
aws-region: ${{ secrets.AWS_REGION }}

# Using Environment Variables for non-sensitive data
ECR_REPOSITORY: poc-ecs/api
PROJECT_NAME: poc-ecs
```

### Least Privilege IAM
The GitHub Actions role includes only necessary permissions:
- **ECR**: Push/pull images, create repositories
- **ECS**: Update services, manage task definitions
- **VPC**: Create networking resources
- **IAM**: Manage ECS-related roles only
- **S3**: Access to specific Terraform state bucket

## 🔧 Troubleshooting Guide

### Common Issues and Solutions

#### 1. OIDC Authentication Failures
```yaml
Error: Could not assume role with OIDC
```

**Solutions**:
- Verify `AWS_ROLE_ARN` secret is correct
- Check that branch name is allowed in OIDC trust policy
- Ensure IAM role has necessary permissions

#### 2. Terraform State Lock
```yaml
Error: Error acquiring the state lock
```

**Solutions**:
- Wait for other operations to complete
- Manually unlock via AWS console (DynamoDB)
- Use `terraform force-unlock` if safe

#### 3. Docker Build Failures
```yaml
Error: failed to solve: failed to compute cache key
```

**Solutions**:
- Check Dockerfile syntax
- Verify all files referenced in Dockerfile exist
- Clear GitHub Actions cache if corrupted

#### 4. ECS Deployment Failures
```yaml
Service failed to stabilize
```

**Solutions**:
- Check ALB health check configuration
- Verify container is listening on correct port
- Review CloudWatch logs for application errors
- Ensure sufficient memory/CPU allocated

### Debugging Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster poc-ecs-cluster --services poc-ecs-api-service

# View recent ECS events
aws ecs describe-services --cluster poc-ecs-cluster --services poc-ecs-api-service --query 'services[0].events[0:5]'

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:...

# View application logs
aws logs tail /ecs/poc-ecs/api --follow
```

## 🎯 Success Criteria

After implementing the complete CI/CD pipeline, you should have:

- ✅ **Automated Infrastructure Deployment**: Terraform changes deploy automatically
- ✅ **Containerized Application Pipeline**: Docker builds and ECS deployments
- ✅ **Secure Authentication**: OIDC-based passwordless deployments
- ✅ **Zero-Downtime Deployments**: Rolling updates with health checks
- ✅ **Cost Management**: Automated shutdown and resource optimization
- ✅ **Monitoring and Observability**: Comprehensive logging and metrics
- ✅ **Rollback Capabilities**: Easy reversion to previous versions

## 🚀 Next Steps

### Advanced CI/CD Features
1. **Multi-Environment Support**: Add staging and production pipelines
2. **Blue/Green Deployments**: Implement advanced deployment strategies
3. **Canary Releases**: Gradual rollout with automatic rollback
4. **Integration Testing**: Automated testing in deployed environment
5. **Security Scanning**: Container vulnerability scanning
6. **Performance Testing**: Load testing in CI/CD pipeline

### Monitoring Enhancements
1. **Custom Dashboards**: CloudWatch dashboards for application metrics
2. **Alerting**: PagerDuty/Slack integration for critical failures
3. **Distributed Tracing**: AWS X-Ray for request tracing
4. **Log Analysis**: Elasticsearch/OpenSearch for log analytics

### Security Improvements
1. **Secrets Management**: AWS Secrets Manager integration
2. **Network Security**: VPC endpoints for all AWS services
3. **Compliance**: SOC2/HIPAA compliance features
4. **Audit Logging**: Comprehensive audit trail

---

**🎯 Success Criteria**: You now have a production-ready CI/CD pipeline that automatically deploys your containerized application to AWS ECS with full security, monitoring, and cost optimization!