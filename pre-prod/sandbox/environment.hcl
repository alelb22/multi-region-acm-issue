# Set common variables for the environment.
# This is automatically pulled in in the root terragrunt.hcl configuration to
#   feed forward to the child modules.

locals {
  env = "sbx"
  environment = "sandbox"
  environment_tags = {
    "Stage"       = "pre-prod"
    "environment" = "sandbox"
    "daily_bkp"   = "false"
  }
}
