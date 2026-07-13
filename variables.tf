variable "organization_configuration" {
  type = object({
    notification_email            = string
    language                      = optional(string, "en")
    default_usage_location        = optional(string, null)
    marketing_notification_emails = optional(list(string), [])
    privacy_contact_email         = optional(string, null)
    privacy_statement_url         = optional(string, null)
  })
  description = <<-DESCRIPTION
  An object describing the tenant's organization settings:
  - `notification_email` - The e-mail address to receive technical and security compliance notifications from the Entra ID tenant. Required.
  - `language` - The tenant default language as ISO 639-1 code. Defaults to `en`.
  - `default_usage_location` - Two-letter ISO 3166 country code used as usage location for users without an explicit value (e.g. users synced via Entra Connect). Relevant for data residency/GDPR. Defaults to `null` (no change).
  - `marketing_notification_emails` - A list of e-mail addresses to receive marketing notifications. Defaults to `[]` (disabled).
  - `privacy_contact_email` - E-mail address of the global privacy contact. Defaults to `null`.
  - `privacy_statement_url` - URL to the organization's privacy statement. Must start with http:// or https://, max 255 characters. Defaults to `null`.
  DESCRIPTION

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.organization_configuration.notification_email))
    error_message = "organization_configuration.notification_email must be a valid SMTP email address."
  }

  validation {
    condition = (
      var.organization_configuration.default_usage_location == null ||
      can(regex("^[A-Z]{2}$", var.organization_configuration.default_usage_location))
    )
    error_message = "organization_configuration.default_usage_location must be a valid two-letter ISO 3166 country code (e.g. 'AT', 'DE')."
  }

  validation {
    condition = (
      var.organization_configuration.privacy_contact_email == null ||
      can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.organization_configuration.privacy_contact_email))
    )
    error_message = "organization_configuration.privacy_contact_email must be a valid SMTP email address."
  }

  validation {
    condition = (
      var.organization_configuration.privacy_statement_url == null ||
      try(
        can(regex("^https?://", var.organization_configuration.privacy_statement_url)) && length(var.organization_configuration.privacy_statement_url) <= 255,
        false
      )
    )
    error_message = "organization_configuration.privacy_statement_url must start with http:// or https:// and be at most 255 characters."
  }
}

variable "tenant_id" {
  type        = string
  description = "The Entra ID tenant id."
}

variable "enable_security_defaults" {
  type        = bool
  description = "Enable Entra ID security defaults. Defaults to `true`. See https://learn.microsoft.com/en-us/entra/fundamentals/security-defaults for more details."
  default     = true
}

variable "allow_invites_from" {
  type        = string
  description = "Indicates who can invite external users to the organization. The possible values are: `none`, `adminsAndGuestInviters`, `adminsGuestInvitersAndAllMembers` or `everyone`. Defaults to `adminsAndGuestInviters`"
  default     = "adminsAndGuestInviters"

  validation {
    condition     = contains(["none", "adminsAndGuestInviters", "adminsGuestInvitersAndAllMembers", "everyone"], var.allow_invites_from)
    error_message = "allow_invites_from must be one of \"none\", \"adminsAndGuestInviters\", \"adminsGuestInvitersAndAllMembers\", \"everyone\"."
  }
}

variable "allowed_to_use_sspr" {
  type        = bool
  description = "Indicates whether users are allowed to use Self-Service Password Reset (SSPR). Defaults to `true`."
  default     = true
}

variable "guest_user_role" {
  type        = string
  description = "The role that should be granted to guest user. Currently following roles are supported: `user`, `guestUser` and `restrictedGuestUser`. Defaults to `restrictedGuestUser`."
  default     = "restrictedGuestUser"

  validation {
    condition     = contains(["user", "guestUser", "restrictedGuestUser"], var.guest_user_role)
    error_message = "guest_user_role must be one of \"user\", \"guestUser\", \"restrictedGuestUser\"."
  }
}

variable "allowed_to_create_apps" {
  type        = bool
  description = "Indicates whether users are allowed to create Application Registrations and Enterprise Apps. Defaults to `false`."
  default     = false
}

variable "allowed_to_create_tenants" {
  type        = bool
  description = "Indicates whether users are allowed to create tenants. Defaults to `false`."
  default     = false
}

variable "allowed_to_create_security_groups" {
  type        = bool
  description = "Indicates whether users are allowed to create security groups. Defaults to `false`."
  default     = false
}

variable "allow_user_apps_consent" {
  type        = bool
  description = "Indicates whether users are allowed to grant permissions (consent) to applications. Defaults to `false`."
  default     = false
}

variable "permission_grant_policies_assigned" {
  type        = list(string)
  description = "A list of permission grant policies to assign to users. See https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/configure-user-consent for more details."
  default = [
    "ManagePermissionGrantsForOwnedResource.microsoft-dynamically-managed-permissions-for-chat",
    "ManagePermissionGrantsForOwnedResource.microsoft-dynamically-managed-permissions-for-team",
  ]
}

variable "authentication_methods_policy_configuration" {
  type = object({
    microsoft_authenticator = optional(object({
      enabled = optional(bool, true)
    }), {})
    email = optional(object({
      enabled                            = optional(bool, false)
      allow_external_id_to_use_email_otp = optional(string, "default")
      included_groups                    = optional(list(string), [])
      excluded_groups                    = optional(list(string), [])
    }), {})
    fido2 = optional(object({
      enabled                              = optional(bool, true)
      is_attestation_enforced              = optional(bool, false)
      is_self_service_registration_allowed = optional(bool, true)
      included_groups                      = optional(list(string), ["all_users"])
      excluded_groups                      = optional(list(string), [])
      passkey_profiles = optional(list(object({
        id                      = string
        name                    = string
        groups                  = optional(list(string), ["all_users"])
        passkey_types           = optional(list(string), ["deviceBound", "synced"])
        attestation_enforcement = optional(string, "disabled")
        key_restrictions = optional(object({
          is_enforced      = optional(bool, false)
          enforcement_type = optional(string, "block")
          aa_guids         = optional(list(string), [])
        }), {})
        })), [{
        id   = "00000000-0000-0000-0000-000000000001"
        name = "Default passkey profile"
      }])
    }), {}),
    software_oath = optional(object({
      enabled = optional(bool, false)
    }), {})
  })
  default = {
    microsoft_authenticator = {}
    email                   = {}
    fido2                   = {}
    software_oath           = {}
  }
  description = <<-DESCRIPTION
  An object describing the tenant's authentication methods policy configuration:
  - `microsoft_authenticator` - Configure the Microsoft Authenticator policy
    - `enabled` - Enables or disables the authentication method. Default to `true`.
  - `email` - Configure the Email OTP policy
    - `enabled` - Enables or disables the authentication method. Default to `false`.
    - `allow_external_id_to_use_email_otp` - Determines whether email OTP is usable by external users for authentication. The possible values are: `default`, `enabled`, `disabled` or `unknownFutureValue`. Defaults to `default`.
    - `included_groups` - A list of groups that are enabled to use the authentication method. Default to `[]`.
    - `excluded_groups` - A list of groups groups that are excluded from the policy. Default to `[]`.
  - `fido2` - Configure the FIDO2 policy
    - `enabled` - Enables or disables the authentication method. Default to `true`.
    - `is_attestation_enforced` - Determines whether attestation must be enforced for passkey (FIDO2) registration. This property is **deprecated** and will be removed in October 2027. Default to `false`.
    - `is_self_service_registration_allowed` - Determines if users can register new passkeys (FIDO2). Default to `true`.
    - `included_groups` - A list of groups that are enabled to use the authentication method. Default to `[]`.
    - `excluded_groups` - A list of groups groups that are excluded from the policy. Default to `[]`.
    - `passkey_profiles` - A list of passkey profile objects.
      - `id` - The passkey profile identifier. Must be a valid GUID.
      - `name` - Name of the passkey profile.
      - `groups` - The groups this profile is used for. Must be one of the groups in `included_groups`.
      - `passkey_types` - Specifies which types of passkeys are targeted in this passkey profile. The possible values are: `deviceBound`, `synced`, `unknownFutureValue`.
      - `attestation_enforcement` - Determines whether attestation must be enforced for passkey (FIDO2) registration. The possible values are: `disabled`, `registrationOnly`, `unknownFutureValue`.
      - `key_restrictions` - Represents the key restrictions that are enforced as part of the FIDO2 security keys authentication methods policy.
        - `is_enforced` - Determines if the configured key enforcement is enabled.
        - `enforcement_type` - Enforcement type. The possible values are `allow`, `block`.
        - `aa_guids` - A list of Authenticator Attestation GUIDs. AADGUIDs define key types and manufacturers.
  - `software_oath` - Configure the Software OATH policy
    - `enabled` - Represents whether users can register this authentication method. Default to `false`.
  DESCRIPTION
}

variable "domains" {
  type = map(object({
    name                                 = string
    is_default                           = optional(bool, false)
    password_notification_window_in_days = optional(number, 14)
    password_validity_period_in_days     = optional(number, 2147483647)
    supported_services                   = optional(list(string), [])
    trigger_verify_action                = optional(bool, false)
  }))
  default     = {}
  description = <<-DESCRIPTION
  A map of domains to configure for the Entra tenant. Defaults to `{}` (no domains). The map key is arbitrary; the value supports the following attributes:
  - `name` - The fully qualified name of the domain.
  - `is_default` - Set to `true` if this is the default domain that is used for user creation. There's only one default domain per tenant. Defaults to `false`.
  - `password_notification_window_in_days` - Specifies the number of days before a user receives notification that their password expires. Defaults to `14` days.
  - `password_validity_period_in_days` - Specifies the length of time that a password is valid before it must be changed. Defaults to `2147483647`, meaning passwords do not expire.
  - `supported_services` - The capabilities assigned to the domain. The values can include `Email`, `OfficeCommunicationsOnline` and `Yammer`. Defaults to `[]`.
  - `trigger_verify_action` - Set to true to trigger domain verification. You *must* configure the required DNS records first. Refer to https://learn.microsoft.com/en-us/entra/identity/users/domains-manage for more information. Defaults to `false`.
  DESCRIPTION
}

variable "allow_user_consent_for_risky_apps" {
  type        = bool
  description = "Indicates whether users are allowed to consent to risky applications. Microsoft strongly recommends keeping this set to false. See https://learn.microsoft.com/en-us/graph/api/resources/authorizationpolicy"
  default     = false
}

variable "allowed_to_sign_up_email_based_subscriptions" {
  type        = bool
  description = "Indicates whether users are allowed to sign up for email-based subscriptions. Defaults to `false`."
  default     = false
}

variable "block_msol_powershell" {
  type        = bool
  description = "Indicates whether users are blocked from using MSOL PowerShell. Defaults to `false`."
  default     = false
}
