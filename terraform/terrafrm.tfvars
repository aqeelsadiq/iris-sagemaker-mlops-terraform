# AWS
aws_region = "us-east-1"

# Project Naming
project_name = "iris-mlops"

# S3 bucket (must be globally unique)
s3_bucket_name = "sagemaker-aqeel-iris-us-east-1-387867038403"

# SageMaker Model Registry
model_package_group_name = "iris-model-group-aqeel"

# GitHub repo format: OWNER/REPO
github_repo = "aqeelsadiq/iris-sagemaker-mlops-terraform"

# Only allow main branch to deploy
github_allowed_refs = [
  "refs/heads/main"
]