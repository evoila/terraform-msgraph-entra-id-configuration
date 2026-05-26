variables {
  authentication_methods_policy_configuration = {
    fido2 = {
      enabled                              = true
      is_attestation_enforced              = true
      is_self_service_registration_allowed = false
      included_groups = [
        "11111111-2222-3333-4444-555555555555",
        "66666666-7777-8888-9999-000000000000"
      ]
      excluded_groups = []
      passkey_profiles = [
        {
          id     = "00000000-0000-0000-0000-000000000001"
          name   = "Default passkey profile"
          groups = ["11111111-2222-3333-4444-555555555555"]
        },
        {
          id     = "00000000-0000-0000-0000-000000000002"
          name   = "Some other profile"
          groups = ["66666666-7777-8888-9999-000000000000"]
        },
      ]
    }
  }
}

mock_provider "msgraph" {
  mock_resource "msgraph_update_resource" {
    defaults = {
      url = "policies/authenticationMethodsPolicy/authenticationMethodConfigurations/fido2"
      body = {
        state                            = "enabled"
        isAttestationEnforced            = true
        isSelfServiceRegistrationAllowed = false
        includeTargets = [
          {
            id                     = "11111111-2222-3333-4444-555555555555"
            isRegistrationRequired = false
            targetType             = "group"
            allowedPasskeyProfiles = ["00000000-0000-0000-0000-000000000001"]
          },
          {
            id                     = "66666666-7777-8888-9999-000000000000"
            isRegistrationRequired = false
            targetType             = "group"
            allowedPasskeyProfiles = ["00000000-0000-0000-0000-000000000002"]
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
    condition     = msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.state == "enabled"
    error_message = "FIDO2 auth method state should be enabled"
  }
}

run "test_is_attestation_enforced" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.isAttestationEnforced == var.authentication_methods_policy_configuration.fido2.is_attestation_enforced
    error_message = "Attestation enforcement should be enabled"
  }
}

run "test_is_self_service_registration_allowed" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.isSelfServiceRegistrationAllowed == var.authentication_methods_policy_configuration.fido2.is_self_service_registration_allowed
    error_message = "Self-service registration should be disabled"
  }

}

run "test_target_groups" {
  command = apply

  assert {
    condition     = length(msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.includeTargets) == length(var.authentication_methods_policy_configuration.fido2.included_groups)
    error_message = "Should have the required number of included groups"
  }
  assert {
    condition     = length(msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.excludeTargets) == length(var.authentication_methods_policy_configuration.fido2.excluded_groups)
    error_message = "Should have the required number of excluded groups"
  }
}

run "test_assigned_passkey_profiles" {
  command = apply

  assert {
    condition     = contains(msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.includeTargets[0].allowedPasskeyProfiles, "00000000-0000-0000-0000-000000000001")
    error_message = "The passkey profile '00000000-0000-0000-0000-000000000001' must be assigned to the target group '${msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.includeTargets[0].id}'."
  }

  assert {
    condition     = contains(msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.includeTargets[1].allowedPasskeyProfiles, "00000000-0000-0000-0000-000000000002")
    error_message = "The passkey profile '00000000-0000-0000-0000-000000000002' must be assigned to the target group '${msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.includeTargets[1].id}'."
  }
}
