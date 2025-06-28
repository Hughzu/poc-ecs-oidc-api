output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = "Name of the GitHub Actions IAM role"
  value       = aws_iam_role.github_actions.name
}

# GitHub Actions secrets to configure
output "github_secrets" {
  description = "Secrets to add to your GitHub repository"
  value = {
    AWS_REGION = var.aws_region
    AWS_ROLE_ARN = aws_iam_role.github_actions.arn
  }
}

output "budget_name" {
  description = "Name of the created budget"
  value       = aws_budgets_budget.monthly_cost_budget.name
}