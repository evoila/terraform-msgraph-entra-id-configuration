locals {
  # Constants for guest access permissions
  # see https://learn.microsoft.com/en-us/entra/identity/users/users-restrict-guest-permissions
  guest_user_role_id = {
    user                = "a0b1b346-4d3e-4e8b-98f8-753987be4970"
    guestUser           = "10dae51f-b6af-4016-8d66-8c2a99b929b3"
    restrictedGuestUser = "2af84b1e-32c8-42b7-82bc-daa82404023b"
  }

  permission_grant_policies_assigned_with_user_consent = concat(
    var.permission_grant_policies_assigned,
    [
      "ManagePermissionGrantsForSelf.microsoft-user-default-allow-consent-apps",
      "ManagePermissionGrantsForSelf.microsoft-user-default-recommended",
    ]
  )

  # 'Translate'
  fido2_passkey_profiles = [for profile in var.authentication_methods_policy_configuration.fido2.passkey_profiles : {
    id                     = profile.id
    name                   = profile.name
    passkeyTypes           = join(",", profile.passkey_types)
    attestationEnforcement = profile.attestation_enforcement
    keyRestrictions = {
      isEnforced      = profile.key_restrictions.is_enforced
      enforcementType = profile.key_restrictions.enforcement_type
      aaGuids         = profile.key_restrictions.aa_guids
    }
  }]

  domain_detail = { for key, domain in try(data.msgraph_resource.domains.output.all.value, {}) : domain.id => domain }
}
