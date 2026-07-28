terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    msgraph = {
      source  = "microsoft/msgraph"
      version = "~> 0.3"
    }
  }
}

provider "msgraph" {}

module "entra" {
  source = "../../" # Replace with correct module path

  tenant_id = "11111111-2222-3333-4444-555555555555"

  organization_configuration = {
    notification_email     = "jane.doe@contoso.com"
    language               = "en"
    default_usage_location = "US"
  }

  authentication_methods_policy_configuration = {
    # Enable FIDO2 (passkeys) and define two passkey profiles targeting different groups: a
    # hardware-security-key-only profile (with AAGUID and attestation restrictions) for a
    # "Privileged Users" group, and a more permissive profile (allowing device-bound and
    # synced/platform passkeys) for everyone else.
    fido2 = {
      enabled                              = true
      is_self_service_registration_allowed = true
      included_groups = [
        "11111111-2222-3333-4444-555555555555", # "Privileged Users" group object ID
        "all_users",                            # special value: targets every user in the tenant
      ]
      passkey_profiles = [
        {
          id     = "00000000-0000-0000-0000-000000000001"
          name   = "Privileged users - hardware security keys only"
          groups = ["11111111-2222-3333-4444-555555555555"]
          # Only device-bound (hardware security key) passkeys are allowed for this profile.
          passkey_types           = ["deviceBound"]
          attestation_enforcement = "registrationOnly"
          key_restrictions = {
            is_enforced      = true
            enforcement_type = "allow"
            # Restrict registration to specific hardware key models (AAGUIDs), e.g. YubiKey 5 series.
            aa_guids = [
              "2fc0579f-8113-47ea-b116-bb5a8db9202a",
              "ee882879-721c-4913-9775-3dfcce97072a",
            ]
          }
        },
        {
          id            = "00000000-0000-0000-0000-000000000002"
          name          = "All users - device-bound and synced passkeys"
          groups        = ["all_users"]
          passkey_types = ["deviceBound", "synced"]
        },
      ]
    }

    # Explicitly disable SMS as an authentication method. Microsoft is deprecating SMS
    # authentication (see https://www.microsoft.com/en-us/security/blog/2026/07/13/microsoft-entra-id-security-updates-passkeys-are-the-default-authentication-method-in-entra-id/)
    # in favor of phishing-resistant methods such as passkeys (FIDO2).
    sms = {
      enabled = false
    }
  }
}
