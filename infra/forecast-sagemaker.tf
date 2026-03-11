resource "aws_sagemaker_domain" "forecast_sagemaker_domain" {
  domain_name = lower(replace(local.placeholder, "%name%", "forecast-sagemaker-domain"))
  auth_mode   = var.forecast_sagemaker_domain_auth_mode

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  app_network_access_type = "VpcOnly"

  default_user_settings {
    execution_role    = module.forecast_sagemaker_exec_role.arn
    security_groups   = [module.forecast_sagemaker_domain_sg.security_group_id]
    studio_web_portal = "ENABLED"

    space_storage_settings {
      default_ebs_storage_settings {
        default_ebs_volume_size_in_gb = 30
        maximum_ebs_volume_size_in_gb = 30
      }
    }
  }

  default_space_settings {
    execution_role  = module.forecast_sagemaker_exec_role.arn
    security_groups = [module.forecast_sagemaker_domain_sg.security_group_id]
    space_storage_settings {
      default_ebs_storage_settings {
        default_ebs_volume_size_in_gb = 30
        maximum_ebs_volume_size_in_gb = 30
      }
    }
  }
  domain_settings {
    security_group_ids = [module.forecast_sagemaker_domain_sg.security_group_id]
  }
  tags = var.tags
}


########################
# Sagemaker User Profile
########################
resource "aws_sagemaker_user_profile" "forecast_user_profile" {
  domain_id         = aws_sagemaker_domain.forecast_sagemaker_domain.id
  user_profile_name = "ForecastUserProfile"
  user_settings {
    execution_role = module.forecast_sagemaker_user_role.arn
  }
}

#######################
# Sagemaker Model Group
#######################
resource "aws_sagemaker_model_package_group" "forecast_model_group" {
  model_package_group_name        = lower(replace(local.placeholder, "%name%", "forecast-model-group"))
  model_package_group_description = "Model package group for Forecast models"

  tags = var.tags
}