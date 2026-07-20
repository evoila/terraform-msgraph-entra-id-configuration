# Configure custom domains for the Entra ID tenant
# see https://learn.microsoft.com/en-us/graph/api/resources/domain
locals {
  domain_detail = { for key, domain in try(data.msgraph_resource.domains.output.all.value, {}) : domain.id => domain }
}

# Create domain objects...
resource "msgraph_resource" "domains" {
  for_each = var.domains

  url = "domains"

  body = {
    id                = each.value.name
    isDefault         = try(local.domain_detail[each.value.name].isVerified, false) ? each.value.is_default : false
    supportedServices = each.value.supported_services
  }
}

# ... then update the password policy properties. (This MUST be done in a separate PATCH request.)
# Note: Microsoft Graph rejects password policy updates on unverified domains, so they are skipped here.
resource "msgraph_update_resource" "domain_password_policy" {
  for_each = { for key, domain in var.domains : key => domain if try(local.domain_detail[domain.name].isVerified, false) == true }

  url = "domains/${each.value.name}"

  body = {
    passwordNotificationWindowInDays = each.value.password_notification_window_in_days
    passwordValidityPeriodInDays     = each.value.password_validity_period_in_days
  }

  depends_on = [msgraph_resource.domains]
}

# Start domain verification process
# see https://learn.microsoft.com/en-us/graph/api/domain-verify
resource "msgraph_resource_action" "domain_verify" {
  for_each = { for key, domain in var.domains : key => domain if domain.trigger_verify_action == true && try(local.domain_detail[domain.name].isVerified, true) == false }

  resource_url = "domains/${each.value.name}"
  action       = "verify"
  method       = "POST"

  body = {}
}
