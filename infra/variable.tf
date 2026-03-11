variable "region" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "project" {
  type    = string
  default = "drc"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type = list(string)
  default = [
    "us-east-1a",
    "us-east-1b"
  ]
}

variable "forecast_sagemaker_domain_auth_mode" {
  description = "Auth mode for SageMaker Domain"
  type        = string
  default     = "IAM"
}

variable "forecast_sagemaker_kernel_instance_type" {
  description = "Default kernel instance type for SageMaker Studio"
  type        = string
  default     = "ml.t3.medium"
}
