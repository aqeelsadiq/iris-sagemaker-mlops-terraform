output "sagemaker_execution_role_arn" {
  value = aws_iam_role.sagemaker_exec.arn
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}