variable "tenant_id" {
  type        = string
  description = "The Entra ID tenant id."
}

variable "tenant_notification_email" {
  type        = string
  description = "The e-mail address to receive technical notifications from the Entra ID tenant."
}

variable "tenant_language" {
  type        = string
  description = "The Entra ID tenant default language. Defaults to `en`."
  default     = "en"
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

variable "guest_user_role" {
  type        = string
  description = "The role that should be granted to guest user. Currently following roles are supported: `user`, `guestUser` and `restrictedGuestUser`. Defaults to `restrictedGuestUser`."
  default     = "restrictedGuestUser"

  validation {
    condition     = contains(["user", "guestUser", "restrictedGuestUser"], var.guest_user_role)
    error_message = "guest_user_role must be one of \"user\", \"guestUser\", \"restrictedGuestUser\"."
  }
}

variable "authentication_methods_policy_configuration" {
  type = object({
    email = optional(object({
      enabled                            = optional(bool, false)
      allow_external_id_to_use_email_otp = optional(string, "default")
      included_groups                    = optional(list(string), [])
      excluded_groups                    = optional(list(string), [])
    }))
    fido2 = optional(object({
      enabled                              = optional(bool, false)
      is_attestation_enforced              = optional(bool, false)
      is_self_service_registration_allowed = optional(bool, true)
      included_groups                      = optional(list(string), [])
      excluded_groups                      = optional(list(string), [])
    }))
  })
  description = "The configuration for the authentication methods policy."
  default = {
    email = {}
    fido2 = {}
  }
}
