remote_state { 
  backend = "s3" 
  generate = { 
    path      = "backend.tf" 
    if_exists = "overwrite" 
  } 
  config = { 
    encrypt        = true 
    key            = "${path_relative_to_include()}/terraform.tfstate" 
    region         = "${local.region}" 
    bucket         = "${local.remote_state_bucket}" 
    dynamodb_table = "${local.remote_state_dynamodb_table}" 
 
  } 
} 
 
generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
  terraform {
    required_version= "${local.terraform_version}"
    required_providers {
      aws = {
        source  = "registry.terraform.io/hashicorp/aws"
        version = "${local.provider_versions.aws_provider}"
      }
    }
  }

  provider "aws" {
    region  = "${local.region}"
  }
  provider "template" {
  }
  provider "null" {
  }

EOF
} 
 
locals { 
 
  default_yaml = find_in_parent_folders("empty.yaml") 
   
  common_var_file_path = "${find_in_parent_folders("common.yaml")}" 
 
  current_module_file_path = "${get_terragrunt_dir()}" 
 
  application_name = basename(local.current_module_file_path) 
 
  environment_name = basename(dirname(dirname(local.current_module_file_path))) 
 
  
  common_environment_var_file_path = "${find_in_parent_folders("${local.environment_name}.yaml", local.default_yaml)}" 
 
  application_specific_var_file_path = "${get_terragrunt_dir()}/${local.application_name}.yaml" 
 
 
  common_inputs                     = yamldecode(file(local.common_var_file_path)) 
  common_environment_inputs         = yamldecode(file(local.common_environment_var_file_path)) 
  application_environment_inputs    = yamldecode(file(local.application_specific_var_file_path)) 
 
  combined_inputs = merge(merge(local.common_inputs, local.common_environment_inputs), local.application_environment_inputs) 
 
  common_app_settings                     = lookup(local.common_inputs, "app_settings", {})  
  common_environment_app_settings         = lookup(local.common_environment_inputs, "app_settings", {}) 
  application_environment_settings        = lookup(local.application_environment_inputs, "app_settings",{}) 
 
 
  combined_app_settings = merge(merge(local.common_app_settings, local.common_environment_app_settings),local.application_environment_settings) 
 
  var_inputs = merge(local.combined_inputs, {app_settings = local.combined_app_settings } ) 
 
  region = local.combined_app_settings.aws_region 
  remote_state_bucket = local.combined_app_settings.remote_state_bucket 
  remote_state_dynamodb_table = local.combined_app_settings.remote_state_dynamodb_table 
 
  provider_versions = local.combined_app_settings.provider_versions
  terraform_version = local.combined_app_settings.terraform_version
 
 
} 
 
inputs = local.var_inputs 