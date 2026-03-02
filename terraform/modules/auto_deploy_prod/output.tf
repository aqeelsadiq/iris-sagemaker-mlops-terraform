output "lambda_name" {
  value = aws_lambda_function.auto_deploy_prod.function_name
}

output "event_rule_name" {
  value = aws_cloudwatch_event_rule.on_model_approved.name
}