module "sagemaker_exec_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  name        = "${var.env}-${var.project}-SageMakerExecutionRole"
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
    AmazonSageMakerFullAccess = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
    CloudWatchLogsFullAccess  = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
    custom                    = module.sagemaker_exec_custom_policy.arn
  }

  tags = var.tags
}



module "auto_deploy_prod_lambda_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  name        = "${var.env}-${var.project}-AutoDeployProdLambdaRole"
  path        = "/"
  description = "Role for AutoDeployProd Lambda"

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
    custom  = module.auto_deploy_prod_lambda_policy.arn
  }

  tags = var.tags
}