data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.lambda_source_dir
  output_path = "${path.module}/auto_deploy_prod.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-AutoDeployProdLambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "${var.project_name}-AutoDeployProdLambdaPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Logs
      {
        Effect = "Allow"
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      },

      # SageMaker operations for deploying endpoint
      {
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

      # Pass SageMaker execution role
      {
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = [var.sagemaker_execution_role_arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "auto_deploy_prod" {
  function_name = "${var.project_name}-auto-deploy-prod"
  role          = aws_iam_role.lambda_role.arn
  handler       = "handler.handler"
  runtime       = "python3.11"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout = 300

  environment {
    variables = {
      REGION              = var.aws_region
      MODEL_PACKAGE_GROUP     = var.model_package_group_name
      PROD_ENDPOINT_NAME      = var.prod_endpoint_name
      SAGEMAKER_EXEC_ROLE_ARN = var.sagemaker_execution_role_arn
      INSTANCE_TYPE           = var.instance_type
      INITIAL_INSTANCE_COUNT  = tostring(var.initial_instance_count)
    }
  }
}

# Trigger when approval status becomes Approved
resource "aws_cloudwatch_event_rule" "on_model_approved" {
  name        = "${var.project_name}-on-model-approved"
  description = "Deploy PROD endpoint when model package is Approved"

  event_pattern = jsonencode({
    source      = ["aws.sagemaker"],
    "detail-type" = ["SageMaker Model Package State Change"],
    detail = {
      ModelApprovalStatus    = ["Approved"],
      ModelPackageGroupName  = [var.model_package_group_name]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.on_model_approved.name
  target_id = "AutoDeployProdLambda"
  arn       = aws_lambda_function.auto_deploy_prod.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_deploy_prod.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.on_model_approved.arn
}

