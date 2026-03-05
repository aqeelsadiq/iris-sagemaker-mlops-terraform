provider "aws" {
  region = var.region

  default_tags {
    tags = merge(
      {
        Environment          = var.env
        Project              = var.project
        created_by_terraform = "true"
      }
    )
  }
}