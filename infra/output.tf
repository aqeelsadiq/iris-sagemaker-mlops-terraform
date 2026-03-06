output "ingestion_bucket_name" {
  value = module.quick_ingestion_s3.s3_bucket_id
}

output "sagemaker_exec_role_arn" {
  value = module.sagemaker_exec_role.arn
}
output "aws_region" {
  value = var.region
}
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "nat_gateway_ips" {
  value = module.vpc.nat_public_ips
}

output "sagemaker_domain_id" {
  value = aws_sagemaker_domain.studio.id
}

output "sagemaker_domain_url" {
  value = aws_sagemaker_domain.studio.url
}