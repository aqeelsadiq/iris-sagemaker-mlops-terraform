module "sagemaker_exec_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.0"

  create_role      = true
  role_name        = "${var.project}-SageMakerExecutionRole"
  role_path        = "/"
  role_description = "SageMaker execution role for pipelines/training/endpoint"

  create_custom_role_trust_policy = true
  custom_role_trust_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "sagemaker.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]

  tags = var.tags
}




module "auto_deploy_prod_lambda_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.0"

  create_role      = true
  role_name        = "${var.project}-AutoDeployProdLambdaRole"
  role_path        = "/"
  role_description = "Role for AutoDeployProd Lambda"

  create_custom_role_trust_policy = true
  custom_role_trust_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
    # "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
  ]

  tags = var.tags
}