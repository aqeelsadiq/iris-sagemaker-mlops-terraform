output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "sagemaker_execution_role_arn" {
  value = module.iam.sagemaker_execution_role_arn
}

output "github_actions_role_arn" {
  value = module.iam.github_actions_role_arn
}

output "model_package_group_name" {
  value = module.sagemaker.model_package_group_name
}

output "prod_auto_deploy_lambda_name" {
  value = module.auto_deploy_prod.lambda_name
}

output "prod_auto_deploy_event_rule_name" {
  value = module.auto_deploy_prod.event_rule_name
}