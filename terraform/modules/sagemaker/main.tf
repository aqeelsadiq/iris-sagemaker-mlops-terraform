resource "aws_sagemaker_model_package_group" "this" {
  model_package_group_name = var.model_package_group_name
  model_package_group_description = "Iris ML Model Registry"
}