# module "forecast_sagemaker_exec_custom_policy" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
#   version = "6.4.0"

#   name        = lower(replace(local.placeholder, "%name%", "forecast-sagemaker-policy"))
#   path        = "/"
#   description = "Custom permissions for SageMaker execution role (S3, KMS, PassRole)"

#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "AllowRawZoneS3Access",
#       "Effect": "Allow",
#       "Action": [
#         "s3:PutObject",
#         "s3:GetObject",
#         "s3:ListBucket",
#         "s3:GetBucketLocation",
#         "s3:DeleteObject"
#       ],
#       "Resource": [
#         "${module.raw-zone.s3_bucket_arn}/*",
#         "${module.raw-zone.s3_bucket_arn}"
#       ]
#     },
#     {
#       "Sid": "AllowSageMakerDomainAccess",
#       "Effect": "Allow",
#       "Action": [
#         "sagemaker:*"
#       ],
#       "Resource": [
#         "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:domain/${aws_sagemaker_domain.forecast_sagemaker_domain.id}",
#         "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:user-profile/${aws_sagemaker_domain.forecast_sagemaker_domain.id}/*",
#         "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:app/${aws_sagemaker_domain.forecast_sagemaker_domain.id}/*",
#         "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:space/${aws_sagemaker_domain.forecast_sagemaker_domain.id}/*",
#         "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:processing-job/*",
#         "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:training-job/*",
#         "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:model-package-group/*",
#         "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:model/*",
#         "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:model-package/*",
#         "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:endpoint/*",
#         "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:endpoint-config/*",
#         "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:pipeline/*",
#         "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:pipeline/pipeline-name/execution/*"

#       ]
#     },
#     {
#       "Sid": "KMSForEncryptedArtifacts",
#       "Effect": "Allow",
#       "Action": [
#         "kms:Decrypt",
#         "kms:Encrypt",
#         "kms:GenerateDataKey",
#         "kms:DescribeKey",
#         "kms:CreateGrant"
#       ],
#       "Resource": "*"
#     },
#     {
#       "Sid": "PassRoleToSageMakerOnly",
#       "Effect": "Allow",
#       "Action": [
#         "iam:PassRole"
#       ],
#       "Resource": "arn:aws:iam::*:role/${terraform.workspace}-${var.project}-*",
#       "Condition": {
#         "StringEquals": {
#           "iam:PassedToService": "sagemaker.amazonaws.com"
#         }
#       }
#     }
#   ]
# }
# EOF

#   tags = var.tags
# }

module "forecast_sagemaker_exec_custom_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.4.0"

  name        = lower(replace(local.placeholder, "%name%", "forecast-sagemaker-policy"))
  path        = "/"
  description = "Custom permissions for SageMaker execution role (S3, KMS, PassRole)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRawZoneS3Access"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:DeleteObject"
        ]
        Resource = [
          "${module.raw-zone.s3_bucket_arn}/*",
          "${module.raw-zone.s3_bucket_arn}"
        ]
      },
      {
        Sid    = "AllowS3ListAllBuckets"
        Effect = "Allow"
        Action = ["s3:ListAllMyBuckets"]
        Resource = "*"
      },
      {
        Sid    = "AllowSageMakerJobAndModelActions"
        Effect = "Allow"
        Action = [
          "sagemaker:CreateTrainingJob",
          "sagemaker:DescribeTrainingJob",
          "sagemaker:StopTrainingJob",
          "sagemaker:ListTrainingJobs",
          "sagemaker:CreateProcessingJob",
          "sagemaker:DescribeProcessingJob",
          "sagemaker:StopProcessingJob",
          "sagemaker:ListProcessingJobs",
          "sagemaker:CreateModel",
          "sagemaker:DescribeModel",
          "sagemaker:DeleteModel",
          "sagemaker:ListModels",
          "sagemaker:CreateModelPackage",
          "sagemaker:DescribeModelPackage",
          "sagemaker:DeleteModelPackage",
          "sagemaker:ListModelPackages",
          "sagemaker:CreateModelPackageGroup",
          "sagemaker:DescribeModelPackageGroup",
          "sagemaker:DeleteModelPackageGroup",
          "sagemaker:ListModelPackageGroups",
          "sagemaker:CreateEndpoint",
          "sagemaker:DescribeEndpoint",
          "sagemaker:UpdateEndpoint",
          "sagemaker:DeleteEndpoint",
          "sagemaker:ListEndpoints",
          "sagemaker:InvokeEndpoint",
          "sagemaker:CreateEndpointConfig",
          "sagemaker:DescribeEndpointConfig",
          "sagemaker:DeleteEndpointConfig",
          "sagemaker:ListEndpointConfigs",
          "sagemaker:CreatePipeline",
          "sagemaker:DescribePipeline",
          "sagemaker:UpdatePipeline",
          "sagemaker:DeletePipeline",
          "sagemaker:StartPipelineExecution",
          "sagemaker:StopPipelineExecution",
          "sagemaker:DescribePipelineExecution",
          "sagemaker:ListPipelineExecutions",
          "sagemaker:ListPipelineExecutionSteps",
          "sagemaker:ListPipelines",
          "sagemaker:AddTags",
          "sagemaker:ListTags",
          "sagemaker:Search"
        ]
        Resource = [
          "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:processing-job/*",
          "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:training-job/*",
          "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:model-package-group/*",
          "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:model/*",
          "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:model-package/*",
          "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:endpoint/*",
          "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:endpoint-config/*",
          "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:pipeline/*",
          "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:pipeline/*/execution/*"
        ]
      },
      {
        Sid    = "AllowSageMakerDomainAccess"
        Effect = "Allow"
        Action = [
          "sagemaker:CreateApp",
          "sagemaker:DeleteApp",
          "sagemaker:DescribeApp",
          "sagemaker:ListApps",
          "sagemaker:CreateSpace",
          "sagemaker:DeleteSpace",
          "sagemaker:DescribeSpace",
          "sagemaker:ListSpaces",
          "sagemaker:CreateUserProfile",
          "sagemaker:DescribeUserProfile",
          "sagemaker:DeleteUserProfile",
          "sagemaker:ListUserProfiles",
          "sagemaker:DescribeDomain",
          "sagemaker:CreatePresignedDomainUrl"
        ]
        Resource = [
          "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:domain/${aws_sagemaker_domain.forecast_sagemaker_domain.id}",
          "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:user-profile/${aws_sagemaker_domain.forecast_sagemaker_domain.id}/*",
          "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:app/${aws_sagemaker_domain.forecast_sagemaker_domain.id}/*",
          "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:space/${aws_sagemaker_domain.forecast_sagemaker_domain.id}/*"
        ]
      },
      {
        Sid    = "AllowSageMakerListApis"
        Effect = "Allow"
        Action = [
          "sagemaker:ListTrainingJobs",
          "sagemaker:ListProcessingJobs",
          "sagemaker:ListModels",
          "sagemaker:ListModelPackages",
          "sagemaker:ListModelPackageGroups",
          "sagemaker:ListEndpoints",
          "sagemaker:ListEndpointConfigs",
          "sagemaker:ListPipelines",
          "sagemaker:ListPipelineExecutions",
          "sagemaker:ListPipelineExecutionSteps",
          "sagemaker:Search"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowECRReadForSageMakerImages"
        Effect = "Allow"
        Action = [
          "ecr:SetRepositoryPolicy",
          "ecr:CompleteLayerUpload",
          "ecr:BatchDeleteImage",
          "ecr:UploadLayerPart",
          "ecr:DeleteRepositoryPolicy",
          "ecr:InitiateLayerUpload",
          "ecr:DeleteRepository",
          "ecr:PutImage",
          "ecr:GetAuthorizationToken",      
          "ecr:BatchCheckLayerAvailability",  
          "ecr:GetDownloadUrlForLayer",       
          "ecr:BatchGetImage" 
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowVPCAccess"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:CreateNetworkInterfacePermission",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeVpcs",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups"
        ]
        Resource = "*"
      },
      {
        Sid    = "KMSForEncryptedArtifacts"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      },
      {
        Sid    = "PassRoleToSageMakerOnly"
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${terraform.workspace}-${var.project}-*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "sagemaker.amazonaws.com"
          }
        }
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/sagemaker/*"
      },
    ]
  })

  tags = var.tags
}


module "forecast_auto_deploy_lambda_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.4.0"

  name        = lower(replace(local.placeholder, "%name%", "forecast-lambda-policy"))
  path        = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["sagemaker:*"]
        Resource = [
            "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:domain/${aws_sagemaker_domain.forecast_sagemaker_domain.id}",
            "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:user-profile/${aws_sagemaker_domain.forecast_sagemaker_domain.id}/*",
            "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:app/${aws_sagemaker_domain.forecast_sagemaker_domain.id}/*",
            "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:space/${aws_sagemaker_domain.forecast_sagemaker_domain.id}/*",
            "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:processing-job/*",
            "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:training-job/*",
            "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:model-package-group/*",
            "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:model-package/*",
            "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:model/*",
            "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:endpoint/*",
            "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:endpoint-config/*"
        ]
      },
      {
        Sid      = "PassSageMakerExecRole"
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = module.forecast_sagemaker_exec_role.arn
      }
    ]
  })

  tags = var.tags
}