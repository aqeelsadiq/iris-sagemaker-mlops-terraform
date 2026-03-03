data "aws_caller_identity" "current" {}

#############################
# SageMaker Execution Role
#############################

resource "aws_iam_role" "sagemaker_exec" {
  name = "${var.project_name}-SageMakerExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "sagemaker.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "sagemaker_exec_policy" {
  name = "${var.project_name}-SageMakerExecPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # S3: bucket + objects (your project bucket)
      {
        Sid    = "S3ListBucket"
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = var.bucket_arn
      },
      {
        Sid    = "S3ObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${var.bucket_arn}/*"
      },

      # SageMaker
      {
        Sid    = "SageMakerAll"
        Effect = "Allow"
        Action = ["sagemaker:*"]
        Resource = "*"
      },

      # CloudWatch Logs (enough for endpoint + processing/training logs)
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },

      # ECR pull (needed when SageMaker endpoint pulls the inference image)
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

      # KMS (only needed if your bucket/model artifacts use SSE-KMS; safe to include)
      {
        Sid    = "KMSForEncryptedArtifacts"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },

      # PassRole restricted to SageMaker only (recommended)
      {
        Sid    = "PassRoleToSageMakerOnly"
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = "arn:aws:iam::*:role/${var.project_name}-*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "sagemaker.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_attach" {
  role       = aws_iam_role.sagemaker_exec.name
  policy_arn = aws_iam_policy.sagemaker_exec_policy.arn
}

#############################
# GitHub OIDC Role
#############################

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

locals {
  github_sub_patterns = [
    for r in var.github_allowed_refs :
    "repo:${var.github_repo}:${r}"
  ]
}

resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-GitHubActionsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = local.github_sub_patterns
        }
      }
    }]
  })
}

resource "aws_iam_policy" "github_policy" {
  name = "${var.project_name}-GitHubPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "sagemaker:*"
        ]
        Resource = "*"
      },

      {
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_attach" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_policy.arn
}