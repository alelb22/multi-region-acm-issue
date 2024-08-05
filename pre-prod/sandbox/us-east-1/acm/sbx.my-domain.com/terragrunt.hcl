terraform {
  source = "tfr:///terraform-aws-modules/acm/aws?version=5.0.1"
}

include {
  path = find_in_parent_folders("common-config.hcl")
}

dependency "hosted_zone" {
  config_path = "../../../global/route53/public/sbx.my-domain.com"
}

inputs = {
  # Since the R53 module returns a Map, we need to take the first value
  # of the output given. Learn more at
  # https://developer.hashicorp.com/terraform/language/functions/values
  domain_name = "*.${values(dependency.hosted_zone.outputs.route53_zone_name)[0]}"
  zone_id     = values(dependency.hosted_zone.outputs.route53_zone_zone_id)[0]

  subject_alternative_names = [
    "${values(dependency.hosted_zone.outputs.route53_zone_name)[0]}",
  ]

  validation_method = "DNS"

  # If this is true, the record is created/detroyed without checking if it's used by a different certificate.
  create_route53_records  = true

  # This is false for testing purposes only, since the zone is not delegated.
  wait_for_validation = false

  tags = {
    Name   = values(dependency.hosted_zone.outputs.route53_zone_name)[0]
    ZoneId = values(dependency.hosted_zone.outputs.route53_zone_zone_id)[0]
  }
}