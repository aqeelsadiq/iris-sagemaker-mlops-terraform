region  = "us-east-1"
env     = "dev"
project = "drc"
tags    = {}




vpc_cidr = "10.0.0.0/16"
azs = [
  "us-east-1a",
  "us-east-1b"
]
public_subnets = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]
private_subnets = [
  "10.0.11.0/24",
  "10.0.12.0/24"
]



sagemaker_domain_auth_mode      = "IAM"
sagemaker_kernel_instance_type  = "ml.t3.medium"