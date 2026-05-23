variables {
  authentication_methods_policy_configuration = {
    microsoft_authenticator = {
      enabled = false
    }
  }
}

mock_provider "msgraph" {
  mock_resource "msgraph_update_resource" {
    defaults = {
      url = "policies/authenticationMethodsPolicy/authenticationMethodConfigurations/microsoftAuthenticator"
      body = {
        state = "disabled"
      }
    }
  }
}

run "test_state" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_microsoft_authenticator_update.body.state == "disabled"
    error_message = "Microsoft Authenticator method state should be disabled"
  }
}
