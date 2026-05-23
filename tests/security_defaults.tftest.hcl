mock_provider "msgraph" {
  mock_resource "msgraph_update_resource" {
    defaults = {
      url = "policies/identitySecurityDefaultsEnforcementPolicy"
      body = {
        isEnabled = true
      }
    }
  }
}

# Test case: Security defaults enabled
run "test_security_defaults_enabled" {
  command = apply

  variables {
    enable_security_defaults = true
  }

  assert {
    condition     = msgraph_update_resource.entra_security_defaults_update[0].body.isEnabled == true
    error_message = "Security defaults should be enabled"
  }
}

# Test case: Security defaults disabled => object should not be set
run "test_security_defaults_disabled" {
  command = apply

  variables {
    enable_security_defaults = false
  }

  assert {
    condition     = msgraph_update_resource.entra_security_defaults_update == []
    error_message = "Security defaults should be disabled"
  }
}
