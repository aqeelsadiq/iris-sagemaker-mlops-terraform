module "forecast_sagemaker_domain_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name        = lower(replace(local.placeholder, "%name%", "forecast-sagemaker-domain-sg"))
  description = "Security group for SageMaker Studio Domain"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [ 
    {
      from_port = 0
      to_port  = 0
      protocol = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
   ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow outbound internet"
    }
  ]

  tags = var.tags
}