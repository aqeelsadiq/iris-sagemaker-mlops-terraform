# data "archive_file" "lambda_zip" {
#   type        = "zip"
#   source_dir  = var.lambda_source_dir
#   output_path = "${path.module}/auto_deploy_prod.zip"
# }