output "ingestion_bucket_name" {
  value = module.quick_ingestion_s3.s3_bucket_id
}

output "sagemaker_exec_role_arn" {
  value = module.sagemaker_exec_role.arn
}
output "aws_region" {
  value = var.region
}