module "s3" {
  source          = "./modules/s3"
  bucket_name     = var.s3_bucket_name
}

module "sagemaker" {
  source                    = "./modules/sagemaker"
  model_package_group_name  = var.model_package_group_name
}

module "iam" {
  source                    = "./modules/iam"
  project_name              = var.project_name
  bucket_arn                = module.s3.bucket_arn
  bucket_name               = module.s3.bucket_name
  github_repo               = var.github_repo
  github_allowed_refs       = var.github_allowed_refs
}