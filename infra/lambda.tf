#################################
# Lambda
#################################
module "auto_deploy_prod_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.7.0"

  function_name = lower(replace(local.placeholder, "%name%", "iris-auto-deploy-lambda"))
  trigger_on_package_timestamp = false
  
  runtime = "python3.12"
  handler = "lambda_function.handler"

  build_in_docker = true

  artifacts_dir = "${path.root}/lambdas/quickbook-ingestion2/build/"
  source_path = "./lambda_src/quickbook-ingestion/"

  timeout     = 30
  memory_size = 256

  environment_variables = {
    REGION               = "us-east-1"                       
    MODEL_PACKAGE_GROUP  = aws_sagemaker_model_package_group.model_group.id
    PROD_ENDPOINT_NAME   = "prod-drc-iris-endpoint"
    SAGEMAKER_EXEC_ROLE_ARN = module.sagemaker_exec_role.arn

    INSTANCE_TYPE         = "ml.m5.large"                
    INITIAL_INSTANCE_COUNT = "1"
  }

  create_role = false
  lambda_role = module.auto_deploy_prod_lambda_role.arn

  cloudwatch_logs_retention_in_days = 14
  tags                              = var.tags
}


resource "aws_lambda_permission" "allow_eventbridge_invoke_auto_deploy" {
  statement_id  = "AllowExecutionFromEventBridgeOnModelApproved"
  action        = "lambda:InvokeFunction"
  function_name = module.auto_deploy_prod_lambda.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn = module.on_model_approved_rule.eventbridge_rule_arns["on_model_approved"]
}