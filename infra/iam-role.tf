module "forecast_sagemaker_exec_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  name        = lower(replace(local.placeholder, "%name%", "forecast-sagemaker"))
  path        = "/"
  description = "SageMaker execution role for pipelines/training/endpoint"
  trust_policy_permissions = {
    SageMakerAssumeRole = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["sagemaker.amazonaws.com"]
      }]
    }
  }

  policies = {
    CloudWatchLogsFullAccess  = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
    ForecastSageMakerExecutionPolicy  = module.forecast_sagemaker_exec_custom_policy.arn
  }

  tags = var.tags
}



module "forecast_auto_deploy_lambda_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  name        = lower(replace(local.placeholder, "%name%", "forecast-auto-deploy"))
  path        = "/"
  description = "Role for Forecast Auto-Deploy Lambda"

  trust_policy_permissions = {
    LambdaAssumeRole = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["lambda.amazonaws.com"]
      }]
    }
  }

  policies = {
    AWSLambdaBasicExecutionRole = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    CloudWatchLogsFullAccess    = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
    ForecastAutoDeployLambdaPolicy  = module.forecast_auto_deploy_lambda_policy.arn
  }

  tags = var.tags
}