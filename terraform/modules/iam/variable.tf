variable "project_name" {
  type = string
}

variable "bucket_arn" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "github_allowed_refs" {
  type = list(string)
}