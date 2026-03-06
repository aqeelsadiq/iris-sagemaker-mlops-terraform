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
variable "model_package_group_name" {
  type    = string
  default = "iris-model-group1"
}
# variable "lambda_source_dir" {
#   type = string
# }