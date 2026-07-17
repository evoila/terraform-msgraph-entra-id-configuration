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

variable "access_reviews" {
  type = map(object({
    display_name              = string
    description_for_reviewers = string
    description_for_admins    = optional(string)
    scope = object({
      template      = optional(string)
      template_vars = optional(map(string), {})
      query         = optional(string)
      query_type    = optional(string, "MicrosoftGraph")
      query_root    = optional(string)
    })
    instance_enumeration_scope = optional(object({
      template      = optional(string)
      template_vars = optional(map(string), {})
      query         = optional(string)
      query_type    = optional(string, "MicrosoftGraph")
      query_root    = optional(string)
    }))
    settings = object({
      mail_notifications_enabled         = optional(bool, false)
      reminder_notifications_enabled     = optional(bool, false)
      justification_required_on_approval = optional(bool, false)
      instance_duration_in_days          = optional(number, 30)
      auto_apply_decisions_enabled       = optional(bool, false)
      apply_actions                      = optional(string, "removeAccessApplyAction")
      recurrence = object({
        pattern = optional(object({
          type              = optional(string, "absoluteMonthly")
          interval          = optional(number, 12)
          month             = optional(number, 0)
          day_of_month      = optional(number, 0)
          days_of_week      = optional(list(string), [])
          first_day_of_week = optional(string, "sunday")
          index             = optional(string, "first")
        }))
        range = object({
          start_date            = string
          end_date              = optional(string, "9999-12-31")
          type                  = optional(string, "numbered")
          number_of_occurrences = optional(number, 0)
          recurrence_time_zone  = optional(string, null)
        })
      })

      default_decision_enabled                 = optional(bool, false)
      default_decision                         = optional(string, "Recommendation")
      decision_histories_for_reviewers_enabled = optional(bool, false)

      recommendations_enabled           = optional(bool, true)
      recommendation_look_back_duration = optional(string)
    })
    reviewers = optional(list(object({
      query      = string
      query_type = optional(string, "MicrosoftGraph")
      query_root = optional(string)
    })), [])
    fallback_reviewers = optional(list(object({
      query      = string
      query_type = optional(string, "MicrosoftGraph")
      query_root = optional(string)
    })), [])
    additional_notification_recipients = optional(list(object({
      notification_template_type = optional(string, "CompletedAdditionalRecipients")
      notification_recipient_scope = object({
        query      = string
        query_root = optional(string)
      })
    })), [])
  }))
  default     = {}
  description = <<-DESCRIPTION
  A map of access review definitions to configure for the Entra tenant. Defaults to `{}` (no access reviews). The map key is arbitrary; the value supports the following attributes:
  - `display_name` - Name of access review series.
  - `description_for_reviewers` - Context of the review provided to reviewers in email notifications. Email notifications support up to 256 characters.
  - `description_for_admins` - Context of the review provided to admins. Defaults to contents of `description_for_reviewers`.
  - `scope` - Defines the entities whose access is reviewed. See https://learn.microsoft.com/en-us/graph/api/resources/accessreviewscope. Exactly one of `template` or `query` must be set.
    - `template` - Optional name of a predefined scope template (file base name, without extension) from `templates/access_review_scopes/`. Use this for scope shapes that require more than a flat query, such as reviews of guests/service principals assigned to a role or of users assigned to an application. Mutually exclusive with `query`.
    - `template_vars` - Map of string variables to interpolate into the template named in `template` (for example `group_id`, `role_id`, `inactive_duration`, `service_principal_id`). Defaults to `{}`; ignored for templates that take no variables.
    - `query` - The query representing what will be reviewed in an access review. Required only when `template` is not set.
    - `query_type` - Indicates the type of query. Types include `MicrosoftGraph` and `ARM`. Defaults to `MicrosoftGraph`.
    - `query_root` - In the scenario where reviewers need to be specified dynamically, this property is used to indicate the relative source of the query. This property is only required if a relative query is specified. For example, `./manager`.
  - `instance_enumeration_scope` - In the case of an all groups review, this determines the scope of which groups will be reviewed. See https://learn.microsoft.com/en-us/graph/api/resources/accessreviewscope. Exactly one of `template` or `query` must be set.
    - `template` - Optional name of a predefined scope template (file base name, without extension) from `templates/access_review_instance_enumeration_scopes/`. Mutually exclusive with `query`.
    - `template_vars` - Map of string variables to interpolate into the template named in `template`. Defaults to `{}`; ignored for templates that take no variables.
    - `query` - The query representing what will be reviewed in an access review. Required only when `template` is not set.
    - `query_type` - Indicates the type of query. Types include `MicrosoftGraph` and `ARM`. Defaults to `MicrosoftGraph`.
    - `query_root` - In the scenario where reviewers need to be specified dynamically, this property is used to indicate the relative source of the query. This property is only required if a relative query is specified. For example, `./manager`.
  - `settings` - The settings for an access review series. Recurrence is determined here..
    - `mail_notifications_enabled` - Indicates whether emails are enabled or disabled. Defaults to `false`.
    - `reminder_notifications_enabled` - .
    - `justification_required_on_approval` - Indicates whether reviewers are required to provide justification with their decision. Defaults to `false`.
    - `instance_duration_in_days` - Duration of an access review instance in days. Defaults to `30`.
    - `auto_apply_decisions_enabled` - Indicates whether decisions are automatically applied. When set to `false`, an admin must apply the decisions manually once the reviewer completes the access review. When set to `true`, decisions are applied automatically after the access review instance duration ends, whether or not the reviewers have responded. Defaults to `false`.
    - `apply_actions` - Describes the actions to take once a review is complete. There are two types that are currently supported: `removeAccessApplyAction` (default) and `disableAndDeleteUserApplyAction`.
    - `recurrence` - Detailed settings for recurrence using the standard Outlook recurrence object. See https://learn.microsoft.com/en-us/graph/api/resources/patternedrecurrence for details.
      - `pattern` - The frequency of an event. Do not specify this property for a one-time access review.
        - `type` - The recurrence pattern type: daily, weekly, absoluteMonthly, relativeMonthly, absoluteYearly, relativeYearly.
        - `interval` - The number of units between occurrences, where units can be in days, weeks, months, or years, depending on the type.
        - `month` - The month in which the event occurs. This is a number from 1 to 12.
        - `day_of_month` - The day of the month on which the event occurs. Required if type is absoluteMonthly or absoluteYearly.
        - `days_of_week` - A collection of the days of the week on which the event occurs. The possible values are: sunday, monday, tuesday, wednesday, thursday, friday, saturday.
        - `first_day_of_week` - The first day of the week. The possible values are: sunday, monday, tuesday, wednesday, thursday, friday, saturday. Defaults to `sunday`.
        - `index` - Specifies on which instance of the allowed days specified in daysOfWeek the event occurs, counted from the first instance in the month. The possible values are: first, second, third, fourth, last. Defaults to `first`.
      - `range` - The duration of the access review.
        - `start_date` - The date to start applying the recurrence pattern. The first occurrence of the meeting may be this date or later, depending on the recurrence pattern of the access review.
        - `end_date` - The date to stop applying the recurrence pattern. Defaults to `9999-12-31` (no end date).
        - `type` - The recurrence range. The possible values are: `endDate`, `noEnd`, `numbered`. Defaults to `numbered`.
        - `number_of_occurrences` - The number of times to repeat the event. Required and must be positive if type is `numbered`.
        - `recurrence_time_zone` - Time zone for the startDate and endDate properties. Defaults to `null`.
    - `default_decision_enabled` - Indicates whether the default decision is enabled or disabled when reviewers do not respond. Defaults to `false`.
    - `default_decision` - Decision chosen if defaultDecisionEnabled is enabled. Can be one of `Approve`, `Deny`, or `Recommendation`. Defaults to `Recommendation`.
    - `decision_histories_for_reviewers_enabled` - Indicates whether decisions on previous access review stages are available for reviewers on an accessReviewInstance with multiple subsequent stages. Defaults to `false`.
    - `recommendations_enabled` - Indicates whether decision recommendations are enabled or disabled. Defaults to `true`.
    - `recommendation_look_back_duration` - .
  - `reviewers` - Defines who the reviewers are. Reviewers can be specified as a static list of users (that is, specific users, group owners, and group members) or dynamically in which every user is reviewed by their manager, group or application owners. If none are specified, the review is a self-review (users review their own access). See https://learn.microsoft.com/en-us/graph/api/resources/accessreviewreviewerscope for more details.
    - `query` - The query specifying who will be the reviewer.
    - `query_type` - Indicates the type of query. Types include `MicrosoftGraph` and `ARM`. Defaults to `MicrosoftGraph`.
    - `query_root` - In the scenario where reviewers need to be specified dynamically, this property is used to indicate the relative source of the query. This property is only required if a relative query, for example, `./manager`, is specified. Possible value: `decisions`.
  - `fallback_reviewers` - If provided, the fallback reviewers are asked to complete a review if the primary reviewers do not exist. For example, if managers are selected as reviewers and a principal under review does not have a manager in Microsoft Entra ID, the fallback reviewers are asked to review that principal.
    - `query` - The query specifying who will be the reviewer.
    - `query_type` - Indicates the type of query. Types include `MicrosoftGraph` and `ARM`. Defaults to `MicrosoftGraph`.
    - `query_root` - In the scenario where reviewers need to be specified dynamically, this property is used to indicate the relative source of the query. This property is only required if a relative query, for example, `./manager`, is specified. Possible value: `decisions`.
  - `additional_notification_recipients` - Defines the list of additional users or group members to be notified of the access review progress.
    - `notification_template_type` - Indicates the type of access review email to be sent. Supported template type is `CompletedAdditionalRecipients`, which sends review completion notifications to the recipients. Defaults to `CompletedAdditionalRecipients`.
    - `notificationRecipientScope` - Determines the recipient of the notification email.
      - `query` - Represents the query for who the recipients are. For example, `/groups/{group id}/members` for group members and `/users/{user id} for a specific user.
      - `query_root` - In the scenario where recipients need to be specified dynamically, this property is used to indicate the relative source of the query. This property is only required if a relative query, for example, `./manager`, is specified.
  DESCRIPTION

  validation {
    condition = alltrue([
      for k, v in var.access_reviews : (v.scope.template != null) != (v.scope.query != null)
    ])
    error_message = "Each access_reviews[*].scope must set exactly one of `template` or `query`."
  }

  validation {
    condition = alltrue([
      for k, v in var.access_reviews : v.instance_enumeration_scope == null ? true : (
        (v.instance_enumeration_scope.template != null) != (v.instance_enumeration_scope.query != null)
      )
    ])
    error_message = "Each access_reviews[*].instance_enumeration_scope, if set, must set exactly one of `template` or `query`."
  }

  validation {
    condition = alltrue([
      for k, v in var.access_reviews : v.scope.template == null ? true : contains(
        fileset(path.module, "templates/access_review_scopes/*.tftpl.json"),
        "templates/access_review_scopes/${v.scope.template}.tftpl.json"
      )
    ])
    error_message = "Each access_reviews[*].scope.template must match an existing file name (without extension) in templates/access_review_scopes/."
  }

  validation {
    condition = alltrue([
      for k, v in var.access_reviews : (v.instance_enumeration_scope == null || try(v.instance_enumeration_scope.template, null) == null) ? true : contains(
        fileset(path.module, "templates/access_review_instance_enumeration_scopes/*.tftpl.json"),
        "templates/access_review_instance_enumeration_scopes/${v.instance_enumeration_scope.template}.tftpl.json"
      )
    ])
    error_message = "Each access_reviews[*].instance_enumeration_scope.template must match an existing file name (without extension) in templates/access_review_instance_enumeration_scopes/."
  }

  validation {
    condition = alltrue([
      for k, v in var.access_reviews : v.settings.recurrence.pattern == null ? true : contains(
        ["daily", "weekly", "absoluteMonthly", "relativeMonthly", "absoluteYearly", "relativeYearly"],
        v.settings.recurrence.pattern.type
      )
    ])
    error_message = "Each access_reviews[*].settings.recurrence.pattern.type must be one of: daily, weekly, absoluteMonthly, relativeMonthly, absoluteYearly, relativeYearly."
  }

  validation {
    condition = alltrue([
      for k, v in var.access_reviews : contains(["endDate", "noEnd", "numbered"], v.settings.recurrence.range.type)
    ])
    error_message = "Each access_reviews[*].settings.recurrence.range.type must be one of: endDate, noEnd, numbered."
  }

  validation {
    condition = alltrue([
      for k, v in var.access_reviews : contains(["Approve", "Deny", "Recommendation"], v.settings.default_decision)
    ])
    error_message = "Each access_reviews[*].settings.default_decision must be one of: Approve, Deny, Recommendation."
  }

  validation {
    condition = alltrue([
      for k, v in var.access_reviews : contains(["removeAccessApplyAction", "disableAndDeleteUserApplyAction"], v.settings.apply_actions)
    ])
    error_message = "Each access_reviews[*].settings.apply_actions must be one of: removeAccessApplyAction, disableAndDeleteUserApplyAction."
  }
}

variable "groups" {
  type = map(object({
    display_name                     = string
    mail_nickname                    = string
    description                      = optional(string)
    security_enabled                 = optional(bool, true)
    mail_enabled                     = optional(bool, false)
    group_types                      = optional(list(string), [])
    visibility                       = optional(string)
    is_assignable_to_role            = optional(bool, false)
    membership_rule                  = optional(string)
    membership_rule_processing_state = optional(string, "On")
    owners                           = optional(list(string), [])
    members                          = optional(list(string), [])
  }))
  default     = {}
  description = <<-DESCRIPTION
  A map of Entra ID groups to manage. Defaults to `{}` (no groups). The map key is arbitrary; the value supports the following attributes:
  - `display_name` - The group's display name.
  - `mail_nickname` - The mail alias for the group, unique within the tenant. Required by Microsoft Graph even for groups that are not mail-enabled.
  - `description` - An optional description for the group.
  - `security_enabled` - Whether the group is security-enabled. Defaults to `true`. Must be `true` for security groups and for role-assignable groups.
  - `mail_enabled` - Whether the group is mail-enabled. Defaults to `false`. Must be `true` for Microsoft 365 groups (requires `"Unified"` in `group_types`).
  - `group_types` - Controls the group type, per https://learn.microsoft.com/en-us/graph/api/group-post-groups#grouptypes-options. Must be one of `[]` (assigned-membership security group), `["Unified"]` (assigned-membership Microsoft 365 group), `["DynamicMembership"]` (dynamic security group), or `["Unified", "DynamicMembership"]` (dynamic Microsoft 365 group). Defaults to `[]`.
  - `visibility` - The group's visibility. Can be `Public`, `Private`, or `HiddenMembership`. Only meaningful for Microsoft 365 groups (`"Unified"` in `group_types`).
  - `is_assignable_to_role` - Whether the group can be assigned an Entra ID role. Requires `security_enabled = true`, is incompatible with dynamic membership, and requires `visibility = "Private"`. Defaults to `false`.
  - `membership_rule` - The dynamic membership rule, using Microsoft Graph's membership rule syntax. See https://learn.microsoft.com/en-us/entra/identity/users/groups-dynamic-membership. Requires `group_types` to include `"DynamicMembership"` and requires the tenant to have an Entra ID P1 (or higher) license.
  - `membership_rule_processing_state` - Whether the dynamic membership rule is actively processed. Can be `On` or `Paused`. Only relevant when `membership_rule` is set. Defaults to `On`.
  - `owners` - A list of existing Entra ID object IDs (for example, user object IDs) to set as group owners. This list is fully reconciled on every `terraform apply` (object IDs not listed here are removed as owners). Defaults to `[]`.
  - `members` - A list of existing Entra ID object IDs to set as group members. This list is fully reconciled on every `terraform apply` (object IDs not listed here are removed as members). Not valid together with `membership_rule`, since dynamic group membership is computed by Microsoft Graph. Defaults to `[]`.
  DESCRIPTION

  validation {
    condition = alltrue([
      for k, v in var.groups : can(regex("^[^@()\\\\\\[\\]\";:<>, ]{1,64}$", v.mail_nickname))
    ])
    error_message = "Each groups[*].mail_nickname must be 1-64 characters and must not contain @()\\[]\";:<>, or spaces."
  }

  validation {
    condition = alltrue([
      for k, v in var.groups : alltrue([for group_type in v.group_types : contains(["Unified", "DynamicMembership"], group_type)]) && length(distinct(v.group_types)) == length(v.group_types)
    ])
    error_message = "Each groups[*].group_types must only contain \"Unified\" and/or \"DynamicMembership\", with no duplicates."
  }

  validation {
    condition = alltrue([
      for k, v in var.groups : v.mail_enabled == false || contains(v.group_types, "Unified")
    ])
    error_message = "Each groups[*] with mail_enabled = true must include \"Unified\" in group_types (only Microsoft 365 groups can be mail-enabled)."
  }

  validation {
    condition = alltrue([
      for k, v in var.groups : v.membership_rule == null || contains(v.group_types, "DynamicMembership")
    ])
    error_message = "Each groups[*].membership_rule requires \"DynamicMembership\" in group_types."
  }

  validation {
    condition = alltrue([
      for k, v in var.groups : v.membership_rule == null || length(v.members) == 0
    ])
    error_message = "Each groups[*] with membership_rule set must not also set members, since dynamic group membership is computed by Microsoft Graph."
  }

  validation {
    condition = alltrue([
      for k, v in var.groups : contains(["On", "Paused"], v.membership_rule_processing_state)
    ])
    error_message = "Each groups[*].membership_rule_processing_state must be \"On\" or \"Paused\"."
  }

  validation {
    condition = alltrue([
      for k, v in var.groups : v.visibility == null || contains(["Public", "Private", "HiddenMembership"], try(v.visibility, ""))
    ])
    error_message = "Each groups[*].visibility, if set, must be one of: Public, Private, HiddenMembership."
  }

  validation {
    condition = alltrue([
      for k, v in var.groups : v.is_assignable_to_role == false || (
        v.security_enabled == true &&
        !contains(v.group_types, "DynamicMembership") &&
      v.visibility == "Private")
    ])
    error_message = "Each groups[*] with is_assignable_to_role = true must have security_enabled = true, must not use dynamic membership, and must set visibility = \"Private\"."
  }
}
