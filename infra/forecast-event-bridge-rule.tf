#################################
# EventBridge Rule
#################################
module "forecast_model_approved_rule" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "4.3.0"

  create_bus = false
  rules = {
    (lower(replace(local.placeholder, "%name%", "forecast-model-approved"))) = {
      description = "Deploy PROD endpoint when model package is Approved"
      event_pattern = jsonencode({
        source      = ["aws.sagemaker"]
        detail-type = ["SageMaker Model Package State Change"]
        detail = {
          ModelApprovalStatus   = ["Approved"]
          ModelPackageGroupName = [aws_sagemaker_model_package_group.forecast_model_group.id]
        }
      })
    }
  }
  targets = {
    (lower(replace(local.placeholder, "%name%", "forecast-model-approved"))) = [
      {
        name  = "InvokeLambdaOnModelApproved"
        arn   = module.forecast_auto_deploy_lambda.lambda_function_arn
        input = jsonencode({ "trigger" = "sagemaker-model-approved" })
      }
    ]
  }

  create_role                = true
  role_name                  = lower(replace(local.placeholder, "%name%", "forecast-model-approved-rule-role"))
  attach_lambda_policy       = true
  create_log_delivery        = false
  create_log_delivery_source = false
  lambda_target_arns = [
    module.forecast_auto_deploy_lambda.lambda_function_arn
  ]

  tags = var.tags
}
