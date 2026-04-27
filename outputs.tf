output "organization_properties" {
  value       = data.msgraph_resource.organization.output
  description = "The Entra ID tenant organization properties."
}

output "authorization_policy" {
  value       = data.msgraph_resource.authorization_policy.output
  description = "The Entra ID tenant authorization policy."
}

output "authentication_methods_policy_fido2" {
  value = "none" # data.msgraph_resource.entra_authentication_method_policy_fido2.output
}
