# Configure Entra ID groups
# see https://learn.microsoft.com/en-us/graph/api/resources/group

# Create group objects.
# Note: groupTypes, mailEnabled and isAssignableToRole can only be set here, at creation. They are not
# part of the PATCH /groups/{id} property set (isAssignableToRole is explicitly documented as
# immutable once set; groupTypes/mailEnabled simply aren't accepted by that endpoint), and Graph
# rejects a PATCH request that includes them with a 400 Bad Request - even when reconciling an
# imported group whose values already match. This resource's body is therefore frozen after
# creation via ignore_changes; msgraph_update_resource.groups_update below manages the properties
# that Microsoft Graph does allow updating indefinitely. See
# https://learn.microsoft.com/en-us/graph/api/group-update and
# https://learn.microsoft.com/en-us/graph/api/resources/group.
resource "msgraph_resource" "groups" {
  for_each = var.groups

  url = "groups"

  body = {
    displayName        = each.value.display_name
    mailNickname       = each.value.mail_nickname
    description        = each.value.description
    securityEnabled    = each.value.security_enabled
    mailEnabled        = each.value.mail_enabled
    groupTypes         = each.value.group_types
    visibility         = each.value.visibility
    isAssignableToRole = each.value.is_assignable_to_role
  }

  response_export_values = { "all" = "@" }

  lifecycle {
    ignore_changes = [body]
  }
}

# Keep the subset of group properties Microsoft Graph allows updating indefinitely in sync with
# configuration. See https://learn.microsoft.com/en-us/graph/api/group-update.
resource "msgraph_update_resource" "groups_update" {
  for_each = var.groups

  url = "groups/${msgraph_resource.groups[each.key].id}"

  body = {
    displayName     = each.value.display_name
    mailNickname    = each.value.mail_nickname
    description     = each.value.description
    securityEnabled = each.value.security_enabled
    visibility      = each.value.visibility
  }

  response_export_values = { "all" = "@" }
  depends_on             = [msgraph_resource.groups]
}

# The dynamic membership rule is configured via a separate PATCH request (mirroring the domain
# password policy pattern in domains.tf) and requires an Entra ID P1 (or higher) license.
resource "msgraph_update_resource" "group_membership_rule" {
  for_each = { for key, group in var.groups : key => group if group.membership_rule != null }

  url = "groups/${msgraph_resource.groups[each.key].id}"

  body = {
    membershipRule                = each.value.membership_rule
    membershipRuleProcessingState = each.value.membership_rule_processing_state
  }

  response_export_values = { "all" = "@" }
  depends_on             = [msgraph_resource.groups]

  lifecycle {
    precondition {
      condition     = local.tenant_has_p1_license
      error_message = "Dynamic membership groups (membership_rule) require an Entra ID P1 (or higher) license, which this tenant does not have."
    }
  }
}

# Reconcile group owners: msgraph_resource_collection adds missing and removes extra reference
# entries, which is the provider's documented approach for child reference collections such as
# /groups/{id}/owners/$ref. See https://registry.terraform.io/providers/microsoft/msgraph/latest/docs/resources/resource_collection
resource "msgraph_resource_collection" "group_owners" {
  for_each = { for key, group in var.groups : key => group if length(group.owners) > 0 }

  url           = "groups/${msgraph_resource.groups[each.key].id}/owners/$ref"
  reference_ids = each.value.owners

  response_export_values = { "all" = "@" }
  depends_on             = [msgraph_resource.groups]
}

# Reconcile group members. Not created for dynamic membership groups, since Microsoft Graph
# computes their membership itself and rejects manual member changes.
resource "msgraph_resource_collection" "group_members" {
  for_each = { for key, group in var.groups : key => group if length(group.members) > 0 && group.membership_rule == null }

  url           = "groups/${msgraph_resource.groups[each.key].id}/members/$ref"
  reference_ids = each.value.members

  response_export_values = { "all" = "@" }
  depends_on             = [msgraph_resource.groups]
}
