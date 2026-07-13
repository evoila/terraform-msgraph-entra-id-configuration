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

  assert {
    condition     = msgraph_resource.domains["contoso"].body.isDefault == true
    error_message = "The domain '${var.domains["contoso"].name}' should be set as the default domain since it is verified and is_default = true."
  }

  assert {
    condition     = !contains(keys(msgraph_resource_action.domain_verify), "contoso")
    error_message = "Domain verification must not be triggered for '${var.domains["contoso"].name}' since it is already verified."
  }
}

# Test case: a domain that is not yet verified must never be set as the default domain,
# even if is_default = true was requested, since Microsoft Graph will reject/ignore the change,
# and domain verification must be triggered instead.
run "test_domain_not_verified_forces_default_false_and_triggers_verify" {
  command = apply

  override_data {
    target = data.msgraph_resource.domains
    values = {
      output = {
        all = {
          value = [
            {
              id                               = "contoso.invalid"
              isDefault                        = false
              isInitial                        = false
              isVerified                       = false
              passwordNotificationWindowInDays = 14
              passwordValidityPeriodInDays     = 2147483647
              supportedServices                = ["Email", "OfficeCommunicationsOnline"]
            },
          ]
        }
      }
    }
  }

  assert {
    condition     = msgraph_resource.domains["contoso"].body.isDefault == false
    error_message = "The domain '${var.domains["contoso"].name}' must not be set as the default domain while it is unverified, regardless of is_default = true."
  }

  assert {
    condition     = contains(keys(msgraph_resource_action.domain_verify), "contoso")
    error_message = "Domain verification must be triggered for '${var.domains["contoso"].name}' since trigger_verify_action = true and the domain is not yet verified."
  }
}

run "test_domains_password_policy" {
  command = apply

  assert {
    condition     = msgraph_update_resource.domain_password_policy["contoso"].body.passwordValidityPeriodInDays == 2147483647
    error_message = "The password validity period for domain '${var.domains["contoso"].name}' must be ${var.domains["contoso"].password_validity_period_in_days}."
  }

  assert {
    condition     = msgraph_update_resource.domain_password_policy["contoso"].body.passwordNotificationWindowInDays == 14
    error_message = "The password notification window for domain '${var.domains["contoso"].name}' must be ${var.domains["contoso"].password_notification_window_in_days}."
  }
}

# Test case: multiple domains with mixed verification/trigger states, and the module's
# derived outputs (default_domain, domains_detail) which read from the real tenant state
# rather than from the requested configuration.
run "test_multiple_domains_and_module_outputs" {
  command = apply

  variables {
    domains = {
      contoso = {
        name                  = "contoso.invalid"
        is_default            = true
        trigger_verify_action = true
      }
      secondary = {
        name                  = "fabrikam.invalid"
        is_default            = false
        trigger_verify_action = false
      }
    }
  }

  override_data {
    target = data.msgraph_resource.domains
    values = {
      output = {
        all = {
          value = [
            {
              id                               = "contoso.onmicrosoft.com"
              isDefault                        = true
              isInitial                        = true
              isVerified                       = true
              passwordNotificationWindowInDays = 14
              passwordValidityPeriodInDays     = 2147483647
              supportedServices                = ["Email", "OfficeCommunicationsOnline"]
            },
            {
              id                               = "contoso.invalid"
              isDefault                        = false
              isInitial                        = false
              isVerified                       = false
              passwordNotificationWindowInDays = 14
              passwordValidityPeriodInDays     = 2147483647
              supportedServices                = []
            },
            {
              id                               = "fabrikam.invalid"
              isDefault                        = false
              isInitial                        = false
              isVerified                       = false
              passwordNotificationWindowInDays = 14
              passwordValidityPeriodInDays     = 2147483647
              supportedServices                = []
            },
          ]
        }
      }
    }
  }

  assert {
    condition     = msgraph_resource.domains["contoso"].body.isDefault == false
    error_message = "The domain 'contoso.invalid' must not be default while unverified, even though is_default = true was requested."
  }

  assert {
    condition     = contains(keys(msgraph_resource_action.domain_verify), "contoso")
    error_message = "Domain verification should be triggered for 'contoso.invalid' since trigger_verify_action = true and it is unverified."
  }

  assert {
    condition     = !contains(keys(msgraph_resource_action.domain_verify), "secondary")
    error_message = "Domain verification must not be triggered for 'fabrikam.invalid' since trigger_verify_action = false, even though it is unverified."
  }

  assert {
    condition     = output.default_domain == "contoso.onmicrosoft.com"
    error_message = "The default domain output should reflect the tenant's actual default domain, which is still the initial domain until 'contoso.invalid' is verified."
  }

  assert {
    condition     = length(output.domains_detail) == 3
    error_message = "The domains_detail output should list every domain known to the tenant, not just the ones configured via var.domains."
  }

  assert {
    condition     = contains(keys(output.domains_detail), "fabrikam.invalid")
    error_message = "The domains_detail output should include 'fabrikam.invalid'."
  }
}
