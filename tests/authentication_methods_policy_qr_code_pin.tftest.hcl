variables {
  authentication_methods_policy_configuration = {
    qr_code_pin = {
      enabled                           = true
      pin_length                        = 10
      standard_qr_code_lifetime_in_days = 180
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
      url = "policies/authenticationMethodsPolicy/authenticationMethodConfigurations/qrCodePin"
    }
  }
}

run "test_state" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_qr_code_pin_update.body.state == "enabled"
    error_message = "QR code PIN auth method state should be enabled"
  }

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_qr_code_pin_update.body["@odata.type"] == "#microsoft.graph.qrCodePinAuthenticationMethodConfiguration"
    error_message = "QR code PIN request body must include the qrCodePinAuthenticationMethodConfiguration @odata.type"
  }
}

run "test_pin_length_and_lifetime" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_qr_code_pin_update.body.pinLength == 10
    error_message = "pinLength should match the configured pin_length"
  }

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_qr_code_pin_update.body.standardQRCodeLifetimeInDays == 180
    error_message = "standardQRCodeLifetimeInDays should match the configured standard_qr_code_lifetime_in_days"
  }
}

run "test_target_groups" {
  command = apply

  assert {
    condition     = length(msgraph_update_resource.entra_authentication_method_policy_qr_code_pin_update.body.includeTargets) == length(var.authentication_methods_policy_configuration.qr_code_pin.included_groups)
    error_message = "Should have the required number of included groups"
  }
  assert {
    condition     = length(msgraph_update_resource.entra_authentication_method_policy_qr_code_pin_update.body.excludeTargets) == length(var.authentication_methods_policy_configuration.qr_code_pin.excluded_groups)
    error_message = "Should have the required number of excluded groups"
  }
}

# Test case: with no explicit configuration, QR code PIN should default to disabled with the API defaults.
run "test_defaults" {
  command = apply

  variables {
    authentication_methods_policy_configuration = {
      qr_code_pin = {}
    }
  }

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_qr_code_pin_update.body.state == "disabled"
    error_message = "QR code PIN auth method state should default to disabled"
  }

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_qr_code_pin_update.body.pinLength == 8
    error_message = "pinLength should default to 8"
  }

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_qr_code_pin_update.body.standardQRCodeLifetimeInDays == 365
    error_message = "standardQRCodeLifetimeInDays should default to 365"
  }

  assert {
    condition     = length(msgraph_update_resource.entra_authentication_method_policy_qr_code_pin_update.body.includeTargets) == 0
    error_message = "Should have no included groups by default"
  }
}

run "invalid_pin_length_too_short" {
  command = plan

  variables {
    authentication_methods_policy_configuration = {
      qr_code_pin = {
        pin_length = 7
      }
    }
  }

  expect_failures = [var.authentication_methods_policy_configuration]
}

run "invalid_pin_length_too_long" {
  command = plan

  variables {
    authentication_methods_policy_configuration = {
      qr_code_pin = {
        pin_length = 21
      }
    }
  }

  expect_failures = [var.authentication_methods_policy_configuration]
}

run "invalid_lifetime_zero" {
  command = plan

  variables {
    authentication_methods_policy_configuration = {
      qr_code_pin = {
        standard_qr_code_lifetime_in_days = 0
      }
    }
  }

  expect_failures = [var.authentication_methods_policy_configuration]
}

run "invalid_lifetime_too_long" {
  command = plan

  variables {
    authentication_methods_policy_configuration = {
      qr_code_pin = {
        standard_qr_code_lifetime_in_days = 396
      }
    }
  }

  expect_failures = [var.authentication_methods_policy_configuration]
}
