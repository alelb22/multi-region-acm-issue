# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform/OpenTofu that provides extra tools for working with multiple modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Region where TF state will be stored (to centralize it)
  tf_state_region = "us-east-1"
  # Name of the role that will be assumed to deploy infrastructure.
  deployment_role_name = "replace-with-your-deployment-role-name"
  # Tags that will be applied to ALL resources
  general_tags = {
    "Tag_1"         = "Value 1"
    "Other_TAG"     = "Something else"
  }



  # # # # # # # # # # # # # # # # # # # # # # # # #
  # NO CHANGES SHOULD BE REQUIRED BELOW THIS LINE #
  # # # # # # # # # # # # # # # # # # # # # # # # #

  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract the variables for easy access
  account_name     = local.account_vars.locals.account_name
  aws_account_id   = local.account_vars.locals.aws_account_id
  env              = local.environment_vars.locals.env
  environment      = local.environment_vars.locals.environment
  aws_region       = local.region_vars.locals.aws_region

  # Obtain and properly format tags that are set depending on the environment:
  environment_tags_map = local.environment_vars.locals.environment_tags
  environment_tags_list = [for key, value in local.environment_tags_map : "\"${key}\" = \"${value}\""]
  environment_tags_string = join("\n", local.environment_tags_list)

  # Properly format general tags that are set to all resources:
  general_tags_map = local.general_tags
  general_tags_list = [for key, value in local.general_tags_map : "\"${key}\" = \"${value}\""]
  general_tags_string = join("\n", local.general_tags_list)
}

# Use S3 bucket to store the terraform state
remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "tf-state-${local.account_name}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         =  local.tf_state_region
    dynamodb_table = "tf-locks-${local.account_name}"
    assume_role = {
      role_arn = "arn:aws:iam::${local.aws_account_id}:role/${local.deployment_role_name}"
    }
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Generate provider configuration to assume role
generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" {
  region = "${local.aws_region}"
  assume_role {
    role_arn = "arn:aws:iam::${local.aws_account_id}:role/${local.deployment_role_name}"
  }
  default_tags {
    tags = {
      "Terraform"                         = "true"
      ${local.general_tags_string}
      ${local.environment_tags_string}
    }
  }
}
EOF
}
