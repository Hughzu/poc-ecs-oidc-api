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

# IAM Policy for GitHub Actions (basic permissions for this project)
resource "aws_iam_policy" "github_actions" {
  name        = "${var.project_name}-github-actions-policy"
  description = "Policy for GitHub Actions to deploy ${var.project_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # Basic bucket operations
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:ListBucket",

          # Object operations
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetObjectAcl",
          "s3:GetObjectLegalHold",
          "s3:GetObjectRetention",
          "s3:GetObjectTagging",
          "s3:GetObjectTorrent",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectVersionTorrent",
          "s3:GetBucketObjectLockConfiguration",

          # Bucket configuration
          "s3:GetBucketAcl",
          "s3:PutBucketAcl",
          "s3:GetBucketAccelerateConfiguration",
          "s3:GetBucketAnalyticsConfiguration",
          "s3:GetBucketCORS",
          "s3:PutBucketCORS",
          "s3:GetBucketEncryption",
          "s3:GetBucketIntelligentTieringConfiguration",
          "s3:GetBucketInventoryConfiguration",
          "s3:GetBucketLifecycleConfiguration",
          "s3:GetBucketLocation",
          "s3:GetBucketLogging",
          "s3:GetBucketMetricsConfiguration",
          "s3:GetBucketNotification",
          "s3:GetBucketNotificationConfiguration",
          "s3:GetBucketOwnershipControls",
          "s3:GetBucketPolicy",
          "s3:PutBucketPolicy",
          "s3:GetBucketPolicyStatus",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketRequestPayment",
          "s3:PutBucketRequestPayment",
          "s3:GetBucketTagging",
          "s3:PutBucketTagging",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetBucketWebsite",
          "s3:PutBucketWebsite",

          # Legacy/Alternative configuration names
          "s3:GetAccelerateConfiguration",
          "s3:PutAccelerateConfiguration",
          "s3:GetEncryptionConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:GetReplicationConfiguration",

          # Account-level operations
          "s3:GetAccountPublicAccessBlock",

          # Access Point operations
          "s3:GetAccessPoint",
          "s3:GetAccessPointConfigurationForObjectLambda",
          "s3:GetAccessPointForObjectLambda",
          "s3:GetAccessPointPolicy",
          "s3:GetAccessPointPolicyForObjectLambda",
          "s3:GetAccessPointPolicyStatus",
          "s3:GetAccessPointPolicyStatusForObjectLambda",

          # Analytics and metrics
          "s3:GetAnalyticsConfiguration",
          "s3:GetInventoryConfiguration",
          "s3:GetMetricsConfiguration",

          # Multi-Region Access Point operations
          "s3:GetMultiRegionAccessPoint",
          "s3:GetMultiRegionAccessPointPolicy",
          "s3:GetMultiRegionAccessPointPolicyStatus",
          "s3:GetMultiRegionAccessPointRoutes",

          # Storage Lens operations
          "s3:GetStorageLensConfiguration",
          "s3:GetStorageLensConfigurationTagging",
          "s3:GetStorageLensDashboard",

          # Job operations
          "s3:GetJobTagging"
        ]
        Resource = [
          "arn:aws:s3:::hughze-poc-ecs",
          "arn:aws:s3:::hughze-poc-ecs/*",
          "arn:aws:s3:::poc-ecs-*",
          "arn:aws:s3:::poc-ecs-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          # ECR permissions
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",

          # ECS permissions
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService",

          # CloudWatch Logs
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",

          # IAM (for ECS task roles)
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-github-actions-policy"
  }
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}
