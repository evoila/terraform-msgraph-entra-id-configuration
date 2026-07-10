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
          id                      = "00000000-0000-0000-0000-000000000002"
          name                    = "Some other profile"
          groups                  = ["66666666-7777-8888-9999-000000000000"]
          passkey_types           = ["deviceBound"]
          attestation_enforcement = "registrationOnly"
          key_restrictions = {
            is_enforced      = true
            enforcement_type = "block"
            aa_guids = [
              "2fc0579f-8113-47ea-b116-bb5a8db9202a",
              "d7781e5d-e353-46aa-afe2-3ca49f13332a",
            ]
          }
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

run "test_passkey_profiles" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.passkeyProfiles[0].name == "Default passkey profile"
    error_message = "The first passkey profile should be named 'Default passkey profile'."
  }

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.passkeyProfiles[0].passkeyTypes == "deviceBound,synced"
    error_message = "The first passkey profile should default to targeting both deviceBound and synced passkeys."
  }

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.passkeyProfiles[0].attestationEnforcement == "disabled"
    error_message = "The first passkey profile should default to attestation enforcement 'disabled'."
  }

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.passkeyProfiles[0].keyRestrictions.isEnforced == false
    error_message = "The first passkey profile should default to no key enforcement."
  }

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.passkeyProfiles[1].passkeyTypes == "deviceBound"
    error_message = "The second passkey profile should only target deviceBound passkeys."
  }

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.passkeyProfiles[1].attestationEnforcement == "registrationOnly"
    error_message = "The second passkey profile should enforce attestation for registration only."
  }

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.passkeyProfiles[1].keyRestrictions.isEnforced == true
    error_message = "The second passkey profile should have key restrictions enforced."
  }

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.passkeyProfiles[1].keyRestrictions.enforcementType == "block"
    error_message = "The second passkey profile should block non-allowed authenticators."
  }

  assert {
    condition = msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.passkeyProfiles[1].keyRestrictions.aaGuids == tolist([
      "2fc0579f-8113-47ea-b116-bb5a8db9202a",
      "d7781e5d-e353-46aa-afe2-3ca49f13332a",
    ])
    error_message = "The second passkey profile should restrict to the configured Authenticator Attestation GUIDs."
  }
}

# Test case: with no explicit configuration, FIDO2 should default to enabled, unattested,
# self-service registration allowed, targeting "all_users", with a single default passkey profile.
run "test_state_disabled_and_defaults" {
  command = apply

  variables {
    authentication_methods_policy_configuration = {
      fido2 = {
        enabled = false
      }
    }
  }

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.state == "disabled"
    error_message = "FIDO2 auth method state should be disabled"
  }

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.isAttestationEnforced == false
    error_message = "Attestation enforcement should default to false"
  }

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.isSelfServiceRegistrationAllowed == true
    error_message = "Self-service registration should default to allowed"
  }

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.includeTargets[0].id == "all_users"
    error_message = "FIDO2 should default to targeting the 'all_users' group"
  }

  assert {
    condition     = length(msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.passkeyProfiles) == 1
    error_message = "There should be exactly one default passkey profile"
  }

  assert {
    condition     = msgraph_update_resource.entra_authentication_method_policy_fido2_update.body.passkeyProfiles[0].id == "00000000-0000-0000-0000-000000000001"
    error_message = "The default passkey profile should use the fixed default id"
  }
}
