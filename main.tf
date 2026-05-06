# Update Entra ID tenant/organization properties
# see https://learn.microsoft.com/en-us/graph/api/organization-update
resource "msgraph_update_resource" "entra_organization_update" {
  url = "organization/${var.tenant_id}"

  body = {
    preferredLanguage = var.tenant_language

    # Note: These notification email properties accept arrays but Microsoft Graph API only processes the first email address
    securityComplianceNotificationMails = [var.tenant_notification_email]
    technicalNotificationMails          = [var.tenant_notification_email]
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
# see https://learn.microsoft.com/en-us/entra/fundamentals/security-defaults
resource "msgraph_update_resource" "entra_security_defaults_update" {
  url = "policies/identitySecurityDefaultsEnforcementPolicy"

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
      allowedPasskeyProfiles = []
    }]
    excludeTargets = [for group_id in var.authentication_methods_policy_configuration.fido2.excluded_groups : {
      id                     = group_id
      isRegistrationRequired = false
      targetType             = "group"
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
