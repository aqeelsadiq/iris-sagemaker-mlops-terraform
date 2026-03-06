#################################
# EventBridge Rule
#################################
module "on_model_approved_rule" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "4.3.0"

  create_bus = false
  create_role = false
  rules = {
    on_model_approved = {
      description = "Deploy PROD endpoint when model package is Approved"

      event_pattern = jsonencode({
        source        = ["aws.sagemaker"]
        "detail-type" = ["SageMaker Model Package State Change"]
        detail = {
          ModelApprovalStatus   = ["Approved"]
          ModelPackageGroupName = ["aws_sagemaker_model_package_group.model_group.id"]
        }
      })
    }
  }

  targets = {
    on_model_approved = [
      {
        name = "AutoDeployProdLambda"
        arn  = module.auto_deploy_prod_lambda.lambda_function_arn
        input = jsonencode({ "trigger" = "sagemaker-model-approved" })
      }
    ]
  }

  tags = var.tags
}
