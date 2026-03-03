terraform {
    backend "s3" {
        bucket       = "my-terraform-state-sagemaker"
        key          = "iris-sagemaker-mlops-terraform/dev/terraform.tfstate"
        region       = "us-east-1"
        encrypt      = true
        use_lockfile = true
  }
}