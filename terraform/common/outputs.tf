output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "github_secrets" {
  description = "Secrets to add to your GitHub repository"
  value = module.github-actions-role.github_secrets
}