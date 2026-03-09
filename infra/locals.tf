locals {
  placeholder = "${terraform.workspace}-${var.project}-%name%"

  # Calculate subnet CIDRs based on number of AZs
  subnet_count = length(var.azs)
  
  # Generate public subnet CIDRs
  public_subnet_cidrs = [
    for i in range(local.subnet_count) : 
    cidrsubnet(var.vpc_cidr, 8, i)
  ]
  
  # Generate private subnet CIDRs (offset by subnet_count to avoid overlap)
  private_subnet_cidrs = [
    for i in range(local.subnet_count) : 
    cidrsubnet(var.vpc_cidr, 8, i + local.subnet_count)
  ]
}
