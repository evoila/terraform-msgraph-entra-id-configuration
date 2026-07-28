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

  # Update the tenant details ("Organization configuration")
  organization_configuration = {
    notification_email            = "jane.doe@contoso.com"
    language                      = "en"
    default_usage_location        = "US"
    marketing_notification_emails = ["marketing@contoso.com"]
  }

  # Customize the tenant's authorization policy
  allow_invites_from                = "adminsGuestInvitersAndAllMembers"
  allowed_to_use_sspr               = false
  guest_user_role                   = "guestUser"
  allowed_to_create_apps            = false
  allowed_to_create_tenants         = false
  allowed_to_create_security_groups = true
  block_msol_powershell             = true
}
