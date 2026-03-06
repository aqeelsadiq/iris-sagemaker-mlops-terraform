terraform {
  backend "s3" {
    bucket = "quickbook-ingestion-sagemaker-tf-infra"
    key    = "iris/infra/terraform.tfstate"
    region = "us-east-1"
    use_lockfile = true
  }
}