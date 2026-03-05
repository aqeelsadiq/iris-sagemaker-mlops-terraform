module "sagemaker_exec_custom_policy" {
  source  = "genstackio/policy/aws"
  version = "~> 0.3.1"

  name      = "${var.project}-SageMakerExecCustomPolicy"
  role_name = module.sagemaker_exec_role.iam_role_name

  statements = [
    {
      sid      = "S3ListBucket"
      effect   = "Allow"
      actions  = ["s3:ListBucket"]
      resources = [module.quick_ingestion_s3.s3_bucket_arn]
    },
    {
      sid      = "S3ObjectAccess"
      effect   = "Allow"
      actions  = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
      resources = ["${module.quick_ingestion_s3.s3_bucket_arn}/*"]
    },

    {
      sid     = "ECRPull"
      effect  = "Allow"
      actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ]
      resources = ["*"]
    },

    {
      sid     = "KMSForEncryptedArtifacts"
      effect  = "Allow"
      actions = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
      resources = ["*"]
    },

    {
      sid     = "PassRoleToSageMakerOnly"
      effect  = "Allow"
      actions = ["iam:PassRole"]
      resources = ["arn:aws:iam::*:role/${var.project}-*"]
      conditions = [
        {
          test     = "StringEquals"
          variable = "iam:PassedToService"
          values   = ["sagemaker.amazonaws.com"]
        }
      ]
    }
  ]
}






module "auto_deploy_prod_lambda_policy" {
  source  = "genstackio/policy/aws"
  version = "~> 0.3.1"

  name      = "${var.project}-AutoDeployProdLambdaPolicy"
  role_name = module.auto_deploy_prod_lambda_role.iam_role_name

  statements = [
    {
      sid     = "SageMakerDeployOps"
      effect  = "Allow"
      actions = [
        "sagemaker:ListModelPackages",
        "sagemaker:DescribeModelPackage",
        "sagemaker:CreateModel",
        "sagemaker:CreateEndpointConfig",
        "sagemaker:CreateEndpoint",
        "sagemaker:UpdateEndpoint",
        "sagemaker:DescribeEndpoint"
      ]
      resources = ["*"]
    },
    {
      sid      = "PassSageMakerExecRole"
      effect   = "Allow"
      actions  = ["iam:PassRole"]
      resources = [module.sagemaker_exec_role.iam_role_arn]
    }
  ]
}