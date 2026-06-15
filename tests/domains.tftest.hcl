variables {
  domains = {
    contoso = {
      name                  = "contoso.invalid"
      is_default            = true
      trigger_verify_action = true
      supported_services    = ["Email", "OfficeCommunicationsOnline"]
    }
  }
}

mock_provider "msgraph" {
  mock_data "msgraph_resource" {
    defaults = {
      output = {
        all = {
          value = [
            {
              id                               = "contoso.onmicrosoft.com"
              isDefault                        = false
              isInitial                        = true
              isVerified                       = true
              passwordNotificationWindowInDays = 14
              passwordValidityPeriodInDays     = 2147483647
              supportedServices                = ["Email", "OfficeCommunicationsOnline", ]
            },
            {
              id                               = "contoso.invalid"
              isDefault                        = true
              isInitial                        = false
              isVerified                       = true
              passwordNotificationWindowInDays = 14
              passwordValidityPeriodInDays     = 2147483647
              supportedServices                = ["Email", "OfficeCommunicationsOnline", ]
            },
          ]
        }
      }
    }
  }
}

# Test case: Configure custom domains
run "test_domains" {
  command = apply

  assert {
    condition     = msgraph_resource.domains["contoso"].body.id == var.domains["contoso"].name
    error_message = "The domain '${var.domains["contoso"].name}' should exist."
  }

  assert {
    condition     = msgraph_resource.domains["contoso"].body.supportedServices == var.domains["contoso"].supported_services
    error_message = "The domain '${var.domains["contoso"].name}' should configure the following supported services: ${join(",", var.domains["contoso"].supported_services)}."
  }
}

run "test_domains_password_policy" {
  command = apply

  assert {
    condition     = msgraph_update_resource.domain_password_policy["contoso"].body.passwordValidityPeriodInDays == 2147483647
    error_message = "The password validity period for domain '${var.domains["contoso"].name}' must be ${var.domains["contoso"].password_validity_period_in_days}."
  }
}
