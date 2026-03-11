#################################
# Lambda
#################################
module "forecast_auto_deploy_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.7.0"

  function_name = lower(replace(local.placeholder, "%name%", "forecast-auto-deploy"))

  runtime     = "python3.12"
  handler     = "lambda_function.handler"
  source_path = "${path.root}/lambdas/forecast-autodeploy/"

  timeout     = 30
  memory_size = 256

  environment_variables = {
    REGION                  = var.region
    MODEL_PACKAGE_GROUP     = aws_sagemaker_model_package_group.forecast_model_group.id
    PROD_ENDPOINT_NAME      = lower(replace(local.placeholder, "%name%", "forecast-prod-endpoint"))
    SAGEMAKER_EXEC_ROLE_ARN = module.forecast_sagemaker_exec_role.arn

    INSTANCE_TYPE          = var.forecast_sagemaker_kernel_instance_type
    INITIAL_INSTANCE_COUNT = "1"
  }

  create_role = false
  lambda_role = module.forecast_auto_deploy_lambda_role.arn

  cloudwatch_logs_retention_in_days = 14
  tags                              = var.tags
}


resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.forecast_auto_deploy_lambda.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn = module.forecast_model_approved_rule.eventbridge_rule_arns[
    lower(replace(local.placeholder, "%name%", "forecast-model-approved"))
  ]
}