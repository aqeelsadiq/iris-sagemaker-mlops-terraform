module "quick_ingestion_s3" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.10.0"

  bucket        = lower(replace(local.placeholder, "%name%", "quickbook-ingestion"))
  force_destroy = true

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  versioning = {
    enabled = false
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = var.tags
}