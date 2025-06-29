provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  s3_policy = templatefile("${path.module}/policies/s3-policy.json", {
    bucket_name    = "hughze-poc-ecs"
    project_name   = var.project_name
  })
  
  ecr_policy = templatefile("${path.module}/policies/ecr-policy.json", {
    aws_region     = var.aws_region
    aws_account_id = data.aws_caller_identity.current.account_id
    project_name   = var.project_name
  })
  
  ecs_policy = file("${path.module}/policies/ecs-policy.json")
  logs_policy = file("${path.module}/policies/logs-policy.json")
  vpc_policy = file("${path.module}/policies/vpc-policy.json")
}

# OIDC Identity Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Name = "${var.project_name}-github-oidc"
  }
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              for branch in var.github_branches :
              "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${branch}"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-github-actions-role"
  }
}

# Separate IAM Policies for each service
resource "aws_iam_policy" "github_actions_s3" {
  name        = "${var.project_name}-github-actions-s3-policy"
  description = "S3 permissions for GitHub Actions to deploy ${var.project_name}"
  policy      = local.s3_policy

  tags = {
    Name = "${var.project_name}-github-actions-s3-policy"
  }
}

resource "aws_iam_policy" "github_actions_ecr" {
  name        = "${var.project_name}-github-actions-ecr-policy"
  description = "ECR permissions for GitHub Actions to deploy ${var.project_name}"
  policy      = local.ecr_policy

  tags = {
    Name = "${var.project_name}-github-actions-ecr-policy"
  }
}

resource "aws_iam_policy" "github_actions_ecs" {
  name        = "${var.project_name}-github-actions-ecs-policy"
  description = "ECS permissions for GitHub Actions to deploy ${var.project_name}"
  policy      = local.ecs_policy

  tags = {
    Name = "${var.project_name}-github-actions-ecs-policy"
  }
}

resource "aws_iam_policy" "github_actions_logs" {
  name        = "${var.project_name}-github-actions-logs-policy"
  description = "CloudWatch Logs permissions for GitHub Actions to deploy ${var.project_name}"
  policy      = local.logs_policy

  tags = {
    Name = "${var.project_name}-github-actions-logs-policy"
  }
}

resource "aws_iam_policy" "github_actions_vpc" {
  name        = "${var.project_name}-github-actions-vpc-policy"
  description = "Vpc permissions for GitHub Actions to deploy ${var.project_name}"
  policy      = local.vpc_policy

  tags = {
    Name = "${var.project_name}-github-actions-vpc-policy"
  }
}

# Attach all policies to the role
resource "aws_iam_role_policy_attachment" "github_actions_s3" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_s3.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_ecr.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_ecs" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_ecs.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_logs" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_logs.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_vpc" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_vpc.arn
}

# Budget
resource "aws_budgets_budget" "monthly_cost_budget" {
  name = "${var.project_name}-monthly-budget"

  budget_type  = "COST"
  limit_amount = var.monthly_budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  time_period_start = "2025-01-01_00:00"
  time_period_end   = "2030-06-15_00:00" 

  # 80% threshold alert
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  # 100% threshold alert
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  # Forecasted 100% alert
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }

  tags = {
    Name = "${var.project_name}-monthly-budget"
  }
}
