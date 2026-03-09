module "vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "6.6.0"

    name = lower(replace(local.placeholder, "%name%", "vpc"))
    cidr = var.vpc_cidr
    azs  = var.azs

    public_subnets  = local.public_subnet_cidrs
    private_subnets = local.private_subnet_cidrs
    public_subnet_names = [
      for i, az in var.azs : 
      lower(replace(local.placeholder, "%name%", "public-${az}"))
    ]
    private_subnet_names = [
      for i, az in var.azs : 
      lower(replace(local.placeholder, "%name%", "private-${az}"))
    ]

    enable_dns_support = true
    enable_dns_hostnames = true
    enable_nat_gateway = true
    single_nat_gateway = true
    one_nat_gateway_per_az = false
    map_public_ip_on_launch = true
  
    tags = var.tags
}
