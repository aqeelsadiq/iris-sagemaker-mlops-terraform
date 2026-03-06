module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name = "${var.env}-${var.project}-vpc"
  cidr = var.vpc_cidr

  azs = var.azs

  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_nat_gateway = true
  single_nat_gateway = true
  one_nat_gateway_per_az = false

  map_public_ip_on_launch = true

   tags = var.tags
}