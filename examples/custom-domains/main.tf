terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    msgraph = {
      source  = "microsoft/msgraph"
      version = "~> 0.3"
    }
  }
}

provider "msgraph" {}

module "entra" {
  source = "../../" # Replace with correct module path

  tenant_id = "11111111-2222-3333-4444-555555555555"

  organization_configuration = {
    notification_email     = "jane.doe@contoso.com"
    language               = "en"
    default_usage_location = "US"
  }

  # Configure custom domains for the tenant. The map key is arbitrary and only used
  # to reference the domain within Terraform.
  domains = {
    primary = {
      name               = "contoso.com"
      is_default         = true
      supported_services = ["Email", "OfficeCommunicationsOnline"]
      # Set to true once the required DNS records (see the
      # `domain_verification_records` output) have been created, to trigger
      # domain verification.
      trigger_verify_action = true
    }
    marketing = {
      name       = "contoso-marketing.com"
      is_default = false
    }
  }
}

# DNS records required to verify domains that are not yet verified.
output "domain_verification_records" {
  value = module.entra.domain_verification_records
}

# The domain currently marked as default for user creation.
output "default_domain" {
  value = module.entra.default_domain
}
