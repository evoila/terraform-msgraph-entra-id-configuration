# Configure Entra ID users
# see https://learn.microsoft.com/en-us/graph/api/resources/user

# Auto-generate an initial password for any directly-created user without an explicit entry in
# var.user_passwords. Not created for invited users - they authenticate via their home identity.
# nonsensitive() is safe here: only the map's keys are inspected, never the password values.
resource "random_password" "user" {
  for_each = {
    for key, user in var.users : key => user
    if user.invitation == null && !contains(nonsensitive(keys(var.user_passwords)), key)
  }

  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Direct creation: create/update the user via POST /users, with a module-managed password.
resource "msgraph_resource" "users" {
  for_each = { for key, user in var.users : key => user if user.invitation == null }

  url = "users"

  body = {
    accountEnabled    = each.value.account_enabled
    displayName       = each.value.display_name
    mailNickname      = each.value.mail_nickname
    userPrincipalName = each.value.user_principal_name
    givenName         = each.value.given_name
    surname           = each.value.surname
    jobTitle          = each.value.job_title
    department        = each.value.department
    employeeId        = each.value.employee_id
    usageLocation     = each.value.usage_location
    mobilePhone       = each.value.mobile_phone
    businessPhones    = each.value.business_phone != null ? [each.value.business_phone] : []
    otherMails        = each.value.other_mails
    passwordProfile = {
      password                      = try(var.user_passwords[each.key].password, random_password.user[each.key].result)
      forceChangePasswordNextSignIn = each.value.force_change_password_next_sign_in
    }
  }

  response_export_values = { "all" = "@" }
}

# Invited creation: Microsoft Graph creates the user as a side effect of the invitation and e-mails the
# invitee a redemption link, rather than the module assigning a password.
# see https://learn.microsoft.com/en-us/graph/api/resources/invitation
resource "msgraph_resource" "user_invitations" {
  for_each = { for key, user in var.users : key => user if user.invitation != null }

  url = "invitations"

  body = {
    invitedUserEmailAddress = each.value.invitation.invited_user_email_address
    invitedUserDisplayName  = each.value.display_name
    invitedUserType         = each.value.invitation.invited_user_type
    inviteRedirectUrl       = each.value.invitation.invite_redirect_url
    sendInvitationMessage   = each.value.invitation.send_invitation_message
    invitedUserMessageInfo = {
      customizedMessageBody = each.value.invitation.customized_message_body
      ccRecipients          = [for email in each.value.invitation.cc_recipients : { emailAddress = { address = email } }]
      messageLanguage       = each.value.invitation.message_language
    }
  }

  response_export_values = { "all" = "@" }

  lifecycle {
    precondition {
      condition     = var.allow_invites_from != "none"
      error_message = "Invited users cannot be created while allow_invites_from = \"none\"."
    }
  }
}

# Common user object ID resolution across both creation paths. The invitation resource's own .id is the
# *invitation* object's ID, not the created user's - that comes from output.all.invitedUser.id.
locals {
  user_object_id = merge(
    { for key, user in msgraph_resource.users : key => user.id },
    { for key, inv in msgraph_resource.user_invitations : key => inv.output.all.invitedUser.id },
  )
}

# Properties Microsoft Graph doesn't accept on invitation create, applied uniformly to every user
# (regardless of creation path) so invited users get the same ongoing property management as
# directly-created ones, not just a one-time set at creation.
resource "msgraph_update_resource" "user_properties" {
  for_each = var.users

  url = "users/${local.user_object_id[each.key]}"

  body = {
    displayName    = each.value.display_name
    accountEnabled = each.value.account_enabled
    givenName      = each.value.given_name
    surname        = each.value.surname
    jobTitle       = each.value.job_title
    department     = each.value.department
    employeeId     = each.value.employee_id
    usageLocation  = each.value.usage_location
    mobilePhone    = each.value.mobile_phone
    businessPhones = each.value.business_phone != null ? [each.value.business_phone] : []
    otherMails     = each.value.other_mails
  }

  response_export_values = { "all" = "@" }
  depends_on             = [msgraph_resource.users, msgraph_resource.user_invitations]
}

# Assign built-in Entra ID roles (tenant-wide scope only) to users, regardless of creation path.
# see https://learn.microsoft.com/en-us/graph/api/rbacapplication-post-roleassignments
resource "msgraph_resource" "user_role_assignments" {
  for_each = { for pair in flatten([
    for user_key, user in var.users : [
      for role_name in user.assigned_roles : {
        key       = "${user_key}:${role_name}"
        user_key  = user_key
        role_name = role_name
      }
    ]
  ]) : pair.key => pair }

  url = "roleManagement/directory/roleAssignments"

  body = {
    principalId      = local.user_object_id[each.value.user_key]
    roleDefinitionId = local.directory_role_template_id[each.value.role_name]
    directoryScopeId = "/"
  }

  response_export_values = { "all" = "@" }
  depends_on             = [msgraph_resource.users, msgraph_resource.user_invitations]
}
