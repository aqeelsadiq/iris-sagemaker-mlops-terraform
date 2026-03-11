provider "aws" {
  region = var.region

  # assume_role {
  #   role_arn = "arn:aws:iam::899625651351:role/AvahiAdminAccess"
  # }

  default_tags {
    tags = merge(
      {
        Environment          = terraform.workspace
        Project              = var.project
        created_by_terraform = "true"
      }
    )
  }
}