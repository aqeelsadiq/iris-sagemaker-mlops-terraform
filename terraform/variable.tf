variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "iris-mlops"
}

variable "s3_bucket_name" {
  type = string
}

variable "model_package_group_name" {
  type    = string
  default = "iris-model-group"
}

variable "github_repo" {
  type = string
}

variable "github_allowed_refs" {
  type    = list(string)
  default = ["refs/heads/main"]
}