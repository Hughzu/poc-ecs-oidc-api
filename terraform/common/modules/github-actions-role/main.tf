data "aws_caller_identity" "current" {}

locals {
  s3_policy = file("${path.module}/policies/s3-policy.json")
  ecr_policy = templatefile("${path.module}/policies/ecr-policy.json", {
    aws_region     = var.aws_region
    aws_account_id = data.aws_caller_identity.current.account_id
    project_name   = var.project_name
  })
  ecs_policy = file("${path.module}/policies/ecs-policy.json")
  logs_policy = file("${path.module}/policies/logs-policy.json")
  vpc_policy = file("${path.module}/policies/vpc-policy.json")
  alb_policy = file("${path.module}/policies/alb-policy.json")
  autoscaling_policy = file("${path.module}/policies/asg-policy.json")
  servicediscovery_policy = file("${path.module}/policies/servicediscovery-policy.json")
  iam_policy = file("${path.module}/policies/iam-policy.json")
  ec2_policy = file("${path.module}/policies/ec2-policy.json")
}

resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
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

resource "aws_iam_policy" "github_actions_alb" {
  name        = "${var.project_name}-github-actions-alb-policy"
  description = "ALB permissions for GitHub Actions to deploy ${var.project_name}"
  policy      = local.alb_policy
}

resource "aws_iam_policy" "github_actions_autoscaling" {
  name        = "${var.project_name}-github-actions-autoscaling-policy"
  description = "Auto Scaling permissions for GitHub Actions to deploy ${var.project_name}"
  policy      = local.autoscaling_policy
}

resource "aws_iam_policy" "github_actions_servicediscovery" {
  name        = "${var.project_name}-github-actions-servicediscovery-policy"
  description = "Service Discovery permissions for GitHub Actions to deploy ${var.project_name}"
  policy      = local.servicediscovery_policy
}

resource "aws_iam_policy" "github_actions_iam" {
  name        = "${var.project_name}-github-actions-iam-policy"
  description = "IAM permissions for GitHub Actions to deploy ${var.project_name}"
  policy      = local.iam_policy
}

resource "aws_iam_policy" "github_actions_ec2" {
  name        = "${var.project_name}-github-actions-ec2-policy"
  description = "EC2 permissions for GitHub Actions to deploy ${var.project_name}"
  policy      = local.ec2_policy
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

resource "aws_iam_role_policy_attachment" "github_actions_alb" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_alb.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_autoscaling" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_autoscaling.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_servicediscovery" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_servicediscovery.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_iam" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_iam.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_ec2" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_ec2.arn
}