resource "aws_sagemaker_domain" "studio" {
  domain_name = "${var.env}-${var.project}-studio"
  auth_mode   = var.sagemaker_domain_auth_mode

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  app_network_access_type = "VpcOnly"

  default_user_settings {
    execution_role  = module.sagemaker_exec_role.arn
    security_groups = [module.sagemaker_domain_sg.security_group_id]
    studio_web_portal = "ENABLED"

    space_storage_settings {
      default_ebs_storage_settings {
        default_ebs_volume_size_in_gb = 30
        maximum_ebs_volume_size_in_gb = 30
      }
    }
  }
  
  default_space_settings {
    execution_role  = module.sagemaker_exec_role.arn
    security_groups = [module.sagemaker_domain_sg.security_group_id]
    space_storage_settings {
      default_ebs_storage_settings {
        default_ebs_volume_size_in_gb = 30
        maximum_ebs_volume_size_in_gb = 30
      }
    }
  }
  domain_settings {
    security_group_ids = [ module.sagemaker_domain_sg.security_group_id ]
  }
  tags = var.tags
}



resource "aws_sagemaker_user_profile" "user_profile_name" {
  domain_id         = aws_sagemaker_domain.studio.id
  user_profile_name = "aqeelsadiq"
}


resource "aws_sagemaker_model_package_group" "model_group" {
  model_package_group_name        = var.model_package_group_name
  model_package_group_description = "Model registry for ${var.project}"

  tags = var.tags
}