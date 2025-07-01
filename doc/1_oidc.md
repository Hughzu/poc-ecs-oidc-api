# AWS-GitHub OIDC Setup Guide

This guide walks you through setting up OpenID Connect (OIDC) authentication between GitHub Actions and AWS, enabling passwordless deployments without storing AWS credentials in GitHub secrets.

## 🎯 What You'll Achieve

- Secure, passwordless authentication from GitHub Actions to AWS
- No need to store long-lived AWS credentials in GitHub
- Automatic role assumption based on repository and branch
- Budget monitoring and cost alerts
- Ready-to-use infrastructure for deploying applications

## 📋 Prerequisites

Before starting, ensure you have:

- **AWS Account** with administrative access
- **GitHub Repository** where you want to deploy from
- **Terraform** installed locally (version ≥ 1.0)
- **AWS CLI** configured with appropriate permissions
- **Git** configured for your repository

## 🏗️ Step-by-Step Setup

### Step 1: Configure Your Variables

First, update the configuration in `terraform/common/variables.tf` and `terraform/common/main.tf`:

```hcl
# In terraform/common/main.tf - Update these values
module "github-actions-role" {
  source = "./modules/github-actions-role"
  aws_region = "eu-central-1"  # Your preferred AWS region
  project_name = "your-project-name"  # Change this
  bucket_name = "your-unique-bucket-name"  # Must be globally unique
  github_branches = ["main", "develop"]  # Branches that can deploy
  github_org = "YourGitHubUsername"  # Your GitHub username/org
  github_repo = "your-repo-name"  # Your repository name
  oidc_provider_arn = module.github_oidc_provider.oidc_provider_arn
}

module "budget" {
  source = "./modules/budget"
  project_name = "your-project-name"
  alert_email = "your-email@domain.com"  # Your email for alerts
  monthly_budget_limit = 50  # Budget limit in USD
}
```

### Step 2: Create S3 Bucket for Terraform State

Create an S3 bucket to store Terraform state (replace with your bucket name):

### Step 3: Update Backend Configuration

Update the S3 backend configuration in `terraform/common/versions.tf`:

```hcl
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "your-unique-bucket-name"  # Update this
    key     = "common/terraform.tfstate"
    region  = "eu-central-1"  # Update if needed
    encrypt = true
  }
}
```

### Step 4: Initialize and Deploy Common Infrastructure

Navigate to the common folder and deploy:

```bash
# Navigate to common infrastructure
cd terraform/common

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

**Expected Output:**
```
Apply complete! Resources: X added, 0 changed, 0 destroyed.

Outputs:

aws_account_id = "123456789012"
github_secrets = {
  "AWS_REGION" = "eu-central-1"
  "AWS_ROLE_ARN" = "arn:aws:iam::123456789012:role/your-project-github-actions-role"
}
```

### Step 5: Configure GitHub Repository Secrets

Add the following secrets to your GitHub repository:

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Add these **Repository secrets**:

| Secret Name | Value | Example |
|-------------|-------|---------|
| `AWS_REGION` | Your AWS region | `eu-central-1` |
| `AWS_ROLE_ARN` | The role ARN from Terraform output | `arn:aws:iam::123456789012:role/your-project-github-actions-role` |

### Step 6: Create GitHub Actions Workflow

Create `.github/workflows/test-oidc.yml` in your repository:

```yaml
name: Test OIDC Connection

on:
  workflow_dispatch:  # Manual trigger for testing
  push:
    branches: [main]

permissions:
  id-token: write   # Required for OIDC
  contents: read    # Required for checkout

jobs:
  test-oidc:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          role-session-name: GitHubActions-Test
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Test AWS Access
        run: |
          echo "Testing AWS CLI access..."
          aws sts get-caller-identity
          echo "✅ OIDC connection successful!"
```

### Step 7: Test the Connection

1. **Commit and push** the workflow file to your repository
2. Go to **Actions** tab in your GitHub repository
3. **Manually trigger** the "Test OIDC Connection" workflow
4. Verify the workflow runs successfully and shows your AWS account details

**Expected successful output:**
```
Testing AWS CLI access...
{
    "UserId": "AROA...:GitHubActions-Test",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/your-project-github-actions-role/GitHubActions-Test"
}
✅ OIDC connection successful!
```

## 🎉 Next Steps

With OIDC configured, you can now:

1. **Deploy Application Infrastructure**: Use the `terraform/app` folder to deploy ECS, VPC, and other resources
2. **Set up CI/CD Pipelines**: Create workflows for building and deploying applications
3. **Add More Repositories**: Configure additional repositories to use the same OIDC provider
4. **Customize Permissions**: Modify IAM policies based on your specific needs

## 📚 Additional Resources

- [GitHub OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [AWS IAM OIDC Identity Providers](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## ⚠️ Security Best Practices

- **Least Privilege**: Only grant permissions needed for your specific use cases
- **Branch Protection**: Limit OIDC access to protected branches only
- **Regular Audits**: Periodically review IAM policies and permissions
- **Budget Monitoring**: Keep cost alerts enabled to prevent unexpected charges
- **Rotate Regularly**: While not needed for OIDC, review and update policies regularly

---

**🎯 Success Criteria**: You should now have passwordless authentication from GitHub Actions to AWS, with proper monitoring and security in place!