variables {
  authentication_methods_policy_configuration = {
    email = {
      enabled                            = true
      allow_external_id_to_use_email_otp = "disabled"
      included_groups = [
        "11111111-2222-3333-4444-555555555555",
        "66666666-7777-8888-9999-000000000000"
      ]
      excluded_groups = []
    }
  }
}

mock_provider "msgraph" {
  mock_resource "msgraph_update_resource" {
    defaults = {
      url = "policies/authenticationMethodsPolicy/authenticationMethodConfigurations/email"
      body = {
        state                        = "enabled"
        allowExternalIdToUseEmailOtp = "disabled"
        includeTargets = [
          {
            id                     = "11111111-2222-3333-4444-555555555555"
            isRegistrationRequired = false
            targetType             = "group"
          },
          {
            id                     = "66666666-7777-8888-9999-000000000000"
            isRegistrationRequired = false
            targetType             = "group"
          }
        ]
        excludeTargets = []
      }
    }
  }
}

run "test_state" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_email_update.body.state == "enabled"
    error_message = "Email auth method state should be enabled"
  }
}

run "test_allow_external_id_to_use_email_otp" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_email_update.body.allowExternalIdToUseEmailOtp == var.authentication_methods_policy_configuration.email.allow_external_id_to_use_email_otp
    error_message = "Allow External ID OTP should be true"
  }
}

run "test_target_groups" {
  command = apply

  assert {
    condition     = length(msgraph_update_resource.entra_authentication_method_policy_email_update.body.includeTargets) == length(var.authentication_methods_policy_configuration.email.included_groups)
    error_message = "Should have the required number of included groups"
  }
  assert {
    condition     = length(msgraph_update_resource.entra_authentication_method_policy_email_update.body.excludeTargets) == length(var.authentication_methods_policy_configuration.email.excluded_groups)
    error_message = "Should have the required number of excluded groups"
  }
}
