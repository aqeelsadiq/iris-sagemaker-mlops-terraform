module "forecast_sagemaker_exec_custom_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.4.0"

  name        = lower(replace(local.placeholder, "%name%", "forecast-sagemaker-policy"))
  path        = "/"
  description = "Custom permissions for SageMaker execution role (S3, KMS, PassRole)"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowRawZoneS3Access",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:DeleteObject"
      ],
      "Resource": [
        "${module.raw-zone.s3_bucket_arn}/*",
        "${module.raw-zone.s3_bucket_arn}"
      ]
    },
    {
      "Sid": "AllowSageMakerDomainAccess",
      "Effect": "Allow",
      "Action": [
        "sagemaker:*"
      ],
      "Resource": [
        "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:domain/${aws_sagemaker_domain.forecast_sagemaker_domain.id}",
        "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:user-profile/${aws_sagemaker_domain.forecast_sagemaker_domain.id}/*",
        "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:app/${aws_sagemaker_domain.forecast_sagemaker_domain.id}/*",
        "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:space/${aws_sagemaker_domain.forecast_sagemaker_domain.id}/*"
      ]
    },
    {
      "Sid": "AllowProcessingJobsForPipeline",
      "Effect":  "Allow",
      "Action": [
        "sagemaker:CreateProcessingJob",
        "sagemaker:DescribeProcessingJob",
        "sagemaker:StopProcessingJob",
        "sagemaker:AddTags",
        "sagemaker:ListTags"
      ],
      "Resource": [
        "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:processing-job/*"
      ]
    },
    {
      "Sid": "AllowTrainingJobsForPipeline",
      "Effect": "Allow",
      "Action": [
        "sagemaker:CreateTrainingJob",
        "sagemaker:DescribeTrainingJob",
        "sagemaker:StopTrainingJob",
        "sagemaker:AddTags",
        "sagemaker:ListTags"
      ],
      "Resource": [
        "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:training-job/*"
      ]
    },
    {
      "Sid": "AllowModelPackageGroupActions",
      "Effect": "Allow",
      "Action": [
        "sagemaker:AddTags",
        "sagemaker:ListTags",
        "sagemaker:CreateModelPackage",
        "sagemaker:DescribeModelPackage",
        "sagemaker:UpdateModelPackage",
        "sagemaker:CreateModelPackageGroup",
        "sagemaker:DescribeModelPackageGroup"
      ],
      "Resource": [
        "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:model-package-group/*",
        "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:model-package/*"
      ]
    },
    {
      "Sid": "KMSForEncryptedArtifacts",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    },
    {
      "Sid": "PassRoleToSageMakerOnly",
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": "arn:aws:iam::*:role/${terraform.workspace}-${var.project}-*",
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": "sagemaker.amazonaws.com"
        }
      }
    }
  ]
}
EOF

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
        # Resource = "*"
        Resource = [
            "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:domain/${aws_sagemaker_domain.forecast_sagemaker_domain.id}",
            "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:user-profile/${aws_sagemaker_domain.forecast_sagemaker_domain.id}/*",
            "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:app/${aws_sagemaker_domain.forecast_sagemaker_domain.id}/*",
            "arn:aws:sagemaker:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:space/${aws_sagemaker_domain.forecast_sagemaker_domain.id}/*"
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