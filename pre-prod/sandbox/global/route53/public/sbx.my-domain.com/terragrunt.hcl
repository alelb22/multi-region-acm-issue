terraform {
  source = "tfr:///terraform-aws-modules/route53/aws//modules/zones?version=3.1.0"
}

include {
  path = find_in_parent_folders("common-config.hcl")
  expose = true
}

locals {
  domain_name = "sbx.my-domain.com"
}

inputs = {
  zones = {
    "${local.domain_name}" = {
      comment = "Hosted zone for ${local.domain_name}"
      tags = {
        Name = local.domain_name
      }
    }
  }

  tags = {
    Public               = "true"
    OTHER_EXAMPLE_TAG    = "something"
  }
}
