module "sagemaker_exec_custom_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.4.0"

  name        = "${var.env}-${var.project}-SageMakerExecCustomPolicy"
  path        = "/"
  description = "Custom permissions for SageMaker execution role (S3, ECR pull, KMS, PassRole)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "S3ListBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = module.quick_ingestion_s3.s3_bucket_arn
      },
      {
        Sid      = "S3ObjectAccess"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${module.quick_ingestion_s3.s3_bucket_arn}/*"
      },
      {
        Sid    = "ECRPull"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Sid    = "KMSForEncryptedArtifacts"
        Effect = "Allow"
        Action = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
        Resource = "*"
      },
      {
        Sid    = "PassRoleToSageMakerOnly"
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = "arn:aws:iam::*:role/${var.env}-${var.project}-*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "sagemaker.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}






module "auto_deploy_prod_lambda_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.4.0"

  name        = "${var.env}-${var.project}-AutoDeployProdLambdaPolicy"
  path        = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SageMakerDeployOps"
        Effect = "Allow"
        Action = [
          "sagemaker:ListModelPackages",
          "sagemaker:DescribeModelPackage",
          "sagemaker:CreateModel",
          "sagemaker:CreateEndpointConfig",
          "sagemaker:CreateEndpoint",
          "sagemaker:UpdateEndpoint",
          "sagemaker:DescribeEndpoint"
        ]
        Resource = "*"
      },
      {
        Sid      = "PassSageMakerExecRole"
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = module.sagemaker_exec_role.arn
      }
    ]
  })

  tags = var.tags
}