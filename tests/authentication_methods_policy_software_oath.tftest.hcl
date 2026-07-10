variables {
  authentication_methods_policy_configuration = {
    software_oath = {
      enabled = true
    }
  }
}

mock_provider "msgraph" {
  mock_resource "msgraph_update_resource" {
    defaults = {
      url = "policies/authenticationMethodsPolicy/authenticationMethodConfigurations/softwareOath"
      body = {
        state = "enabled"
      }
    }
  }
}

run "test_state" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_software_oath_update.body.state == "enabled"
    error_message = "Software OATH auth method state should be enabled"
  }
}

# Test case: with no explicit configuration, software OATH should default to disabled.
run "test_state_disabled_by_default" {
  command = apply

  variables {
    authentication_methods_policy_configuration = {
      software_oath = {}
    }
  }

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_software_oath_update.body.state == "disabled"
    error_message = "Software OATH auth method state should default to disabled"
  }
}
