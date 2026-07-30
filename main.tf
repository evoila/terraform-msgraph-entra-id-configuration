# Update Entra ID tenant/organization properties
# see https://learn.microsoft.com/en-us/graph/api/organization-update
resource "msgraph_update_resource" "entra_organization_update" {
  url = "organization/${var.tenant_id}"

  body = {
    preferredLanguage    = var.organization_configuration.language
    defaultUsageLocation = var.organization_configuration.default_usage_location

    # Note: These notification email properties accept arrays but Microsoft Graph API only processes the first email address
    securityComplianceNotificationMails = [var.organization_configuration.notification_email]
    technicalNotificationMails          = [var.organization_configuration.notification_email]
    privacyProfile = {
      contactEmail = var.organization_configuration.privacy_contact_email
      statementUrl = var.organization_configuration.privacy_statement_url
    }
    marketingNotificationEmails = var.organization_configuration.marketing_notification_emails
  }



  response_export_values = {
    "all" = "@"
  }
}

# Configure the tenant's organizational branding (default, non-localized)
# see https://learn.microsoft.com/en-us/graph/api/organizationalbranding-update
resource "msgraph_update_resource" "entra_organizational_branding_update" {
  url = "organization/${var.tenant_id}/branding"

  body = {
    backgroundColor                   = var.organizational_branding_configuration.background_color
    headerBackgroundColor             = var.organizational_branding_configuration.header_background_color
    signInPageText                    = var.organizational_branding_configuration.sign_in_page_text
    usernameHintText                  = var.organizational_branding_configuration.username_hint_text
    customAccountResetCredentialsUrl  = var.organizational_branding_configuration.custom_account_reset_credentials_url
    customCannotAccessYourAccountText = var.organizational_branding_configuration.custom_cannot_access_your_account_text
    customForgotMyPasswordText        = var.organizational_branding_configuration.custom_forgot_my_password_text
    customPrivacyAndCookiesText       = var.organizational_branding_configuration.custom_privacy_and_cookies_text
    customPrivacyAndCookiesUrl        = var.organizational_branding_configuration.custom_privacy_and_cookies_url
    customTermsOfUseText              = var.organizational_branding_configuration.custom_terms_of_use_text
    customTermsOfUseUrl               = var.organizational_branding_configuration.custom_terms_of_use_url
    loginPageLayoutConfiguration = {
      layoutTemplateType = var.organizational_branding_configuration.login_page_layout_configuration.layout_template_type
      isHeaderShown      = var.organizational_branding_configuration.login_page_layout_configuration.is_header_shown
      isFooterShown      = var.organizational_branding_configuration.login_page_layout_configuration.is_footer_shown
    }
    loginPageTextVisibilitySettings = {
      hideAccountResetCredentials = var.organizational_branding_configuration.login_page_text_visibility_settings.hide_account_reset_credentials
      hideCannotAccessYourAccount = var.organizational_branding_configuration.login_page_text_visibility_settings.hide_cannot_access_your_account
      hideForgotMyPassword        = var.organizational_branding_configuration.login_page_text_visibility_settings.hide_forgot_my_password
      hidePrivacyAndCookies       = var.organizational_branding_configuration.login_page_text_visibility_settings.hide_privacy_and_cookies
      hideResetItNow              = var.organizational_branding_configuration.login_page_text_visibility_settings.hide_reset_it_now
      hideTermsOfUse              = var.organizational_branding_configuration.login_page_text_visibility_settings.hide_terms_of_use
    }
  }

  response_export_values = {
    "all" = "@"
  }
}

# Update Entra ID authorization policy properties
# see https://learn.microsoft.com/en-us/graph/api/authorizationpolicy-update
resource "msgraph_update_resource" "entra_authorization_policy_update" {
  url = "policies/authorizationPolicy"

  body = {
    allowInvitesFrom                          = var.allow_invites_from
    allowedToUseSSPR                          = var.allowed_to_use_sspr
    allowEmailVerifiedUsersToJoinOrganization = false # Limited to recommended scenario ONLY. See https://learn.microsoft.com/en-us/azure/active-directory/external-identities/allow-email-verified-users-to-join
    allowUserConsentForRiskyApps              = var.allow_user_consent_for_risky_apps
    allowedToSignUpEmailVerifiedUsers         = var.allowed_to_sign_up_email_based_subscriptions
    blockMsolPowerShell                       = var.block_msol_powershell
    guestUserRoleId                           = local.guest_user_role_id[var.guest_user_role]
    defaultUserRolePermissions = {
      allowedToCreateApps           = var.allowed_to_create_apps
      allowedToCreateTenants        = var.allowed_to_create_tenants
      allowedToCreateSecurityGroups = var.allowed_to_create_security_groups

      # Configure how users consent to applications
      # see https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/configure-user-consent
      permissionGrantPoliciesAssigned = var.allow_user_apps_consent ? local.permission_grant_policies_assigned_with_user_consent : var.permission_grant_policies_assigned
    }
  }

  response_export_values = {
    "all" = "@"
  }
}

# Configure Entra ID security defaults
# see https://learn.microsoft.com/en-us/graph/api/identitysecuritydefaultsenforcementpolicy-update
resource "msgraph_update_resource" "entra_security_defaults_update" {
  count = var.enable_security_defaults ? 1 : 0
  url   = "policies/identitySecurityDefaultsEnforcementPolicy"

  body = {
    isEnabled = var.enable_security_defaults
  }

  response_export_values = {
    "all" = "@"
  }
}

# Configure Microsoft Authenticator authentication method
# see https://learn.microsoft.com/en-us/graph/api/microsoftauthenticatorauthenticationmethodconfiguration-update
resource "msgraph_update_resource" "entra_authentication_method_policy_microsoft_authenticator_update" {
  url = "policies/authenticationMethodsPolicy/authenticationMethodConfigurations/microsoftAuthenticator"

  body = {
    "@odata.type" = "#microsoft.graph.microsoftAuthenticatorAuthenticationMethodConfiguration"
    state         = try(var.authentication_methods_policy_configuration.microsoft_authenticator.enabled, true) ? "enabled" : "disabled"

  }

  response_export_values = {
    "all" = "@"
  }
}


# Configure Email OTP authentication method
# see https://learn.microsoft.com/en-us/graph/api/emailauthenticationmethodconfiguration-update
resource "msgraph_update_resource" "entra_authentication_method_policy_email_update" {
  url = "policies/authenticationMethodsPolicy/authenticationMethodConfigurations/email"

  body = {
    "@odata.type"                = "#microsoft.graph.emailAuthenticationMethodConfiguration"
    state                        = var.authentication_methods_policy_configuration.email.enabled ? "enabled" : "disabled"
    allowExternalIdToUseEmailOtp = var.authentication_methods_policy_configuration.email.allow_external_id_to_use_email_otp
    includeTargets = [for group_id in var.authentication_methods_policy_configuration.email.included_groups : {
      id                     = group_id
      isRegistrationRequired = false
      targetType             = "group"
    }]
    excludeTargets = [for group_id in var.authentication_methods_policy_configuration.email.excluded_groups : {
      id                     = group_id
      isRegistrationRequired = false
      targetType             = "group"
    }]
  }

  response_export_values = {
    "all" = "@"
  }
}

# Configure FIDO2 authentication method
# see https://learn.microsoft.com/en-us/graph/api/fido2authenticationmethodconfiguration-update
resource "msgraph_update_resource" "entra_authentication_method_policy_fido2_update" {
  url = "policies/authenticationMethodsPolicy/authenticationMethodConfigurations/fido2"

  body = {
    "@odata.type"                    = "#microsoft.graph.fido2AuthenticationMethodConfiguration"
    state                            = var.authentication_methods_policy_configuration.fido2.enabled ? "enabled" : "disabled"
    isAttestationEnforced            = var.authentication_methods_policy_configuration.fido2.is_attestation_enforced
    isSelfServiceRegistrationAllowed = var.authentication_methods_policy_configuration.fido2.is_self_service_registration_allowed
    includeTargets = [for group_id in var.authentication_methods_policy_configuration.fido2.included_groups : {
      id                     = group_id
      isRegistrationRequired = false
      targetType             = "group"
      allowedPasskeyProfiles = [for profile in var.authentication_methods_policy_configuration.fido2.passkey_profiles : profile.id if contains(profile.groups, group_id)]
    }]
    excludeTargets = [for group_id in var.authentication_methods_policy_configuration.fido2.excluded_groups : {
      id                     = group_id
      isRegistrationRequired = false
      targetType             = "group"
    }]
    passkeyProfiles = [for profile in var.authentication_methods_policy_configuration.fido2.passkey_profiles : {
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
  }

  response_export_values = {
    "all" = "@"
  }
}

# Configure 3rd party Software OATH authentication method
# see https://learn.microsoft.com/en-us/graph/api/softwareoathauthenticationmethodconfiguration-update
resource "msgraph_update_resource" "entra_authentication_method_policy_software_oath_update" {
  url = "policies/authenticationMethodsPolicy/authenticationMethodConfigurations/softwareOath"

  body = {
    "@odata.type" = "#microsoft.graph.softwareOathAuthenticationMethodConfiguration"
    state         = try(var.authentication_methods_policy_configuration.software_oath.enabled, false) ? "enabled" : "disabled"

  }

  response_export_values = {
    "all" = "@"
  }
}

# Configure SMS authentication method
# see https://learn.microsoft.com/en-us/graph/api/smsauthenticationmethodconfiguration-update
# Warning: SMS authentication method will be deprecated by 1st of February 2027. See https://www.microsoft.com/en-us/security/blog/2026/07/13/microsoft-entra-id-security-updates-passkeys-are-the-default-authentication-method-in-entra-id/
resource "msgraph_update_resource" "entra_authentication_method_policy_sms_update" {
  url = "policies/authenticationMethodsPolicy/authenticationMethodConfigurations/sms"

  body = {
    "@odata.type" = "#microsoft.graph.smsAuthenticationMethodConfiguration"
    state         = try(var.authentication_methods_policy_configuration.sms.enabled, false) ? "enabled" : "disabled"
    includeTargets = [for group_id in var.authentication_methods_policy_configuration.sms.included_groups : {
      id                     = group_id
      isRegistrationRequired = false
      targetType             = "group"
    }]
    excludeTargets = [for group_id in var.authentication_methods_policy_configuration.sms.excluded_groups : {
      id                     = group_id
      isRegistrationRequired = false
      targetType             = "group"
    }]
  }

  response_export_values = {
    "all" = "@"
  }
}
