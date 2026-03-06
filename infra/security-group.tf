module "sagemaker_domain_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name        = "${var.env}-${var.project}-sagemaker-domain-sg"
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

  # ingress_with_self = [
  #   {
  #     from_port   = 0
  #     to_port     = 0
  #     protocol    = "-1"
  #     description = "Allow internal SageMaker communication"
  #   }
  # ]

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