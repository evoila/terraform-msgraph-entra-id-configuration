variables {
  # Check input values deviating from defaults
  allow_invites_from                = "adminsGuestInvitersAndAllMembers"
  allowed_to_use_sspr               = false
  guest_user_role                   = "guestUser"
  allowed_to_create_apps            = true
  allowed_to_create_tenants         = true
  allowed_to_create_security_groups = true
  allow_user_apps_consent           = true
  permission_grant_policies_assigned = [
    "ManagePermissionGrantsForOwnedResource.microsoft-dynamically-managed-permissions-for-chat"
  ]
}

mock_provider "msgraph" {
  mock_resource "msgraph_update_resource" {
    defaults = {
      url = "policies/authorizationPolicy"
      body = {
        allowInvitesFrom                          = "adminsGuestInvitersAndAllMembers"
        allowedToUseSSPR                          = true
        allowEmailVerifiedUsersToJoinOrganization = false
        guestUserRoleId                           = "10dae51f-b6af-4016-8d66-8c2a99b929b3"
        defaultUserRolePermissions = {
          allowedToCreateApps           = true
          allowedToCreateTenants        = true
          allowedToCreateSecurityGroups = true
          permissionGrantPoliciesAssigned = [
            "ManagePermissionGrantsForOwnedResource.microsoft-dynamically-managed-permissions-for-chat",
            "ManagePermissionGrantsForSelf.microsoft-user-default-allow-consent-apps",
            "ManagePermissionGrantsForSelf.microsoft-user-default-recommended"
          ]
        }
      }
    }
  }
}

run "test_allow_invites_from" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_authorization_policy_update.body.allowInvitesFrom == var.allow_invites_from
    error_message = "Allow invites from should be `${var.allow_invites_from}`"
  }
}

run "test_allowed_to_use_sspr" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_authorization_policy_update.body.allowedToUseSSPR == var.allowed_to_use_sspr
    error_message = "Allowed to use SSPR should be `${var.allowed_to_use_sspr}`"
  }
}

run "test_guest_user_role_id" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_authorization_policy_update.body.guestUserRoleId == "10dae51f-b6af-4016-8d66-8c2a99b929b3"
    error_message = "Guest user role id should be `10dae51f-b6af-4016-8d66-8c2a99b929b3` ('guestUser')"
  }
}

run "test_allow_email_verified_users_to_join_organization" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_authorization_policy_update.body.allowEmailVerifiedUsersToJoinOrganization == false
    error_message = "Allow Email verified Users to join must always be `false`"
  }
}

run "update_default_user_role_permissions" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_authorization_policy_update.body.defaultUserRolePermissions.allowedToCreateApps == var.allowed_to_create_apps
    error_message = "Allow to create Apps should be `${var.allowed_to_create_apps}`"
  }
  assert {
    condition     = msgraph_update_resource.entra_authorization_policy_update.body.defaultUserRolePermissions.allowedToCreateTenants == var.allowed_to_create_tenants
    error_message = "Allow to create Tenants should be `${var.allowed_to_create_tenants}`"
  }
  assert {
    condition     = msgraph_update_resource.entra_authorization_policy_update.body.defaultUserRolePermissions.allowedToCreateSecurityGroups == var.allowed_to_create_security_groups
    error_message = "Allow to create Security Groups should be `${var.allowed_to_create_security_groups}`"
  }
  assert {
    condition = msgraph_update_resource.entra_authorization_policy_update.body.defaultUserRolePermissions.permissionGrantPoliciesAssigned == tolist([
      "ManagePermissionGrantsForOwnedResource.microsoft-dynamically-managed-permissions-for-chat",
      "ManagePermissionGrantsForSelf.microsoft-user-default-allow-consent-apps",
      "ManagePermissionGrantsForSelf.microsoft-user-default-recommended"
    ])
    error_message = "Permission grant policies assigned should contain entries for chat and default user consent"
  }
}
