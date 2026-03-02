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

module "auto_deploy_prod" {
  source = "./modules/auto_deploy_prod"

  project_name                 = var.project_name
  aws_region                   = var.aws_region
  model_package_group_name     = var.model_package_group_name
  prod_endpoint_name           = var.prod_endpoint_name
  sagemaker_execution_role_arn = module.iam.sagemaker_execution_role_arn

  lambda_source_dir = "${path.module}/modules/auto_deploy_prod"

  instance_type          = "ml.m5.large"
  initial_instance_count = 1
}