output "github_secrets" {
  description = "Secrets to add to your GitHub repository"
  value = {
    AWS_REGION = var.aws_region
    AWS_ROLE_ARN = aws_iam_role.github_actions.arn
  }
}
