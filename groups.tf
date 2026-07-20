# Configure Entra ID groups
# see https://learn.microsoft.com/en-us/graph/api/resources/group

# Create/update group objects.
# Note: Graph disallows several mail-related properties on the initial create (accessType,
# allowExternalSenders, autoSubscribeNewMembers, hideFromAddressLists, hideFromOutlookClients,
# isFavorite) - these are not exposed by this module yet; exposing them later would require a
# separate PATCH-based resource, following the domain_password_policy pattern below.
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
