output "organization_properties" {
  value       = try(msgraph_update_resource.entra_organization_update.output.all, null)
  description = "The tenant organization properties."
}

output "license_level" {
  value       = local.tenant_license_level
  description = "The tenant license level. Can be 'Free', 'P1' or 'P2'."
}

output "authorization_policy_properties" {
  value       = try(msgraph_update_resource.entra_authorization_policy_update.output.all, null)
  description = "The tenant authorization policy properties."
}

output "security_defaults_properties" {
  value       = try(msgraph_update_resource.entra_security_defaults_update[0].output.all, null)
  description = "The tenant security defaults properties."
}

output "authentication_method_policy_microsoft_authenticator" {
  value       = try(msgraph_update_resource.entra_authentication_method_policy_microsoft_authenticator_update.output.all, null)
  description = "The tenant's Microsoft Authenticator authentication method confiugration."
}

output "authentication_method_policy_email" {
  value       = try(msgraph_update_resource.entra_authentication_method_policy_email_update.output.all, null)
  description = "The tenant's email authentication method confiugration."
}

output "authentication_methods_policy_fido2" {
  value       = try(msgraph_update_resource.entra_authentication_method_policy_fido2_update.output.all, null)
  description = "The tenant's FIDO2 authentication method confiugration."
}

output "authentication_method_policy_software_oath" {
  value       = try(msgraph_update_resource.entra_authentication_method_policy_software_oath_update.output.all, null)
  description = "The tenant's software OATH authentication method confiugration."
}

output "default_domain" {
  value       = one([for domain in try(data.msgraph_resource.domains.output.all.value, {}) : domain.id if domain.isDefault == true])
  description = "Tenant default domain."
}

output "domains_detail" {
  value       = local.domain_detail
  description = "All configured domains."
}

output "domain_verification_records" {
  value       = { for id, domain in try(data.msgraph_resource.domain_verification_records, {}) : id => domain.output.all.value }
  description = "DNS verification record information for all unverified domains."
}

output "groups_detail" {
  value       = { for key, group in msgraph_resource.groups : group.id => try(group.output.all, {}) }
  description = "All configured groups, keyed by group object ID."
}

output "group_ids" {
  value       = { for key, group in msgraph_update_resource.groups_update : key => group.id }
  description = "Map of configured group keys (as used in var.groups) to their Entra ID object IDs, for referencing managed groups from other module inputs."
}

output "user_ids" {
  value       = { for key, user in msgraph_resource.users : key => user.id }
  description = "Object IDs of all managed users, keyed by the map key used in var.users. Useful for referencing module-created users in var.groups[*].members/owners on a later apply."
}

output "users_details" {
  value       = { for key, user in msgraph_resource.users : user.id => try(user.output.all, {}) }
  description = "All configured users, keyed by user object ID, reflecting configured state."
}
