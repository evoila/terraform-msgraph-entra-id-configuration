variables {
  authentication_methods_policy_configuration = {
    sms = {
      enabled = true
      included_groups = [
        "11111111-2222-3333-4444-555555555555",
        "66666666-7777-8888-9999-000000000000"
      ]
      excluded_groups = [
        "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
      ]
    }
  }
}

mock_provider "msgraph" {
  mock_resource "msgraph_update_resource" {
    defaults = {
      url = "policies/authenticationMethodsPolicy/authenticationMethodConfigurations/sms"
      body = {
        state = "enabled"
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
    condition     = msgraph_update_resource.entra_authentication_method_policy_sms_update.body.state == "enabled"
    error_message = "SMS auth method state should be enabled"
  }
}

run "test_target_groups" {
  command = apply

  assert {
    condition     = length(msgraph_update_resource.entra_authentication_method_policy_sms_update.body.includeTargets) == length(var.authentication_methods_policy_configuration.sms.included_groups)
    error_message = "Should have the required number of included groups"
  }
  assert {
    condition     = length(msgraph_update_resource.entra_authentication_method_policy_sms_update.body.excludeTargets) == length(var.authentication_methods_policy_configuration.sms.excluded_groups)
    error_message = "Should have the required number of excluded groups"
  }
}

# Test case: with no explicit configuration, SMS should default to disabled with no target groups.
run "test_state_disabled_by_default" {
  command = apply

  variables {
    authentication_methods_policy_configuration = {
      sms = {}
    }
  }

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_sms_update.body.state == "disabled"
    error_message = "SMS auth method state should default to disabled"
  }

  assert {
    condition     = length(msgraph_update_resource.entra_authentication_method_policy_sms_update.body.includeTargets) == 0
    error_message = "Should have no included groups by default"
  }
}
