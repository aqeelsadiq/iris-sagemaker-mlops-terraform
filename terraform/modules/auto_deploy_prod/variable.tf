variable "project_name" { type = string }
variable "aws_region" { type = string }

variable "model_package_group_name" { type = string }
variable "prod_endpoint_name" { type = string }
variable "sagemaker_execution_role_arn" { type = string }

variable "lambda_source_dir" { type = string }

variable "instance_type" {
  type    = string
  default = "ml.m5.large"
}

variable "initial_instance_count" {
  type    = number
  default = 1
}