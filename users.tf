# Configure Entra ID users
# see https://learn.microsoft.com/en-us/graph/api/resources/user

# Auto-generate an initial password for any user without an explicit entry in var.user_passwords.
# nonsensitive() is safe here: only the map's keys are inspected, never the password values.
resource "random_password" "user" {
  for_each = { for key, user in var.users : key => user if !contains(nonsensitive(keys(var.user_passwords)), key) }

  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create/update user objects.
resource "msgraph_resource" "users" {
  for_each = var.users

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

# Assign built-in Entra ID roles (tenant-wide scope only) to users.
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
    principalId      = msgraph_resource.users[each.value.user_key].id
    roleDefinitionId = local.directory_role_template_id[each.value.role_name]
    directoryScopeId = "/"
  }

  response_export_values = { "all" = "@" }
  depends_on             = [msgraph_resource.users]
}
