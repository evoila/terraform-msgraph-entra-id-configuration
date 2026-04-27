# Update Entra ID tenant/organization properties
# can be used to set notification email addresses and privacy statement (among a few other properties).
resource "msgraph_update_resource" "entra_organization_update" {
  # This resource creates a PATCH (update) request to the organizations endpoint `PATCH /organization/{id}`
  # see https://learn.microsoft.com/en-us/graph/api/organization-update
  url = "organization/${var.tenant_id}"

  body = {
    preferredLanguage = var.tenant_language

    # Note: These notification email properties accept arrays but Microsoft Graph API only processes the first email address
    securityComplianceNotificationMails = [var.tenant_notification_email]
    technicalNotificationMails          = [var.tenant_notification_email]
  }
}

# Update Entra ID authorization policy to...
# - restrict guest user invitations for non-admin users (allowInvitesFrom)
# - restrict application creation for non-admin users (allowedToCreateApps)
# - restrict tenant creation for non-admin users (allowedToCreateTenants)
# - restrict security group creation for non-admin users (allowedToCreateSecurityGroups)
# - restrict guest users to their own properties only (guestUserRoleId)
# - enable self-service password reset (allowedToUseSSPR)
resource "msgraph_update_resource" "entra_authorization_policy_update" {
  # This resource creates a PATCH (update) request to the authorizationPolicy endpoint `PATCH /policies/authorizationPolicy`
  # see https://learn.microsoft.com/en-us/graph/api/authorizationpolicy-update
  url = "policies/authorizationPolicy"

  body = {
    allowInvitesFrom = var.allow_invites_from
    allowedToUseSSPR = true
    guestUserRoleId  = local.guest_user_role_id[var.guest_user_role]
    defaultUserRolePermissions = {
      allowedToCreateApps           = false
      allowedToCreateSecurityGroups = false
      permissionGrantPoliciesAssigned = [
        "ManagePermissionGrantsForOwnedResource.microsoft-dynamically-managed-permissions-for-chat",
        "ManagePermissionGrantsForOwnedResource.microsoft-dynamically-managed-permissions-for-team",
        "ManagePermissionGrantsForSelf.microsoft-user-default-allow-consent-apps",
        "ManagePermissionGrantsForSelf.microsoft-user-default-recommended",
      ]
    }
  }
}

# Configure Entra ID security defaults
# see https://learn.microsoft.com/en-us/entra/fundamentals/security-defaults
resource "msgraph_update_resource" "entra_security_defaults_update" {
  url = "policies/identitySecurityDefaultsEnforcementPolicy"

  body = {
    isEnabled = var.enable_security_defaults
  }
}

# Configure Entra ID authentication methods policy to restrict the number of authentication methods a user can register

# Disable Email OTP authentication method
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
}

# Enable FIDO2 authentication method
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
}
