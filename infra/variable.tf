variable "region" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "env" {
  type    = string
  default = "dev"
}

variable "project" {
  type    = string
  default = "drc"
}



variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = [
    "us-east-1a",
    "us-east-1b"
  ]
}

variable "public_subnets" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "private_subnets" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]
}






variable "sagemaker_domain_auth_mode" {
  description = "Auth mode for SageMaker Domain"
  type        = string
  default     = "IAM"
}

variable "sagemaker_kernel_instance_type" {
  description = "Default kernel instance type for SageMaker Studio"
  type        = string
  default     = "ml.t3.medium"
}

variable "model_package_group_name" {
  description = "SageMaker Model Package Group name"
  type        = string
}