region  = "us-east-1"
project = "drc"
tags    = {}

vpc_cidr = "10.0.0.0/16"
azs = [
  "us-east-1a",
  "us-east-1b"
]

forecast_sagemaker_domain_auth_mode = "IAM"
forecast_sagemaker_kernel_instance_type = "ml.t3.medium"