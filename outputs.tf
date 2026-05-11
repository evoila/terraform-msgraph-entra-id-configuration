output "organization_properties" {
  value       = msgraph_update_resource.entra_organization_update.output.all
  description = "The tenant organization properties."
}

output "authorization_policy_properties" {
  value       = msgraph_update_resource.entra_authorization_policy_update.output.all
  description = "The tenant authorization policy properties."
}

output "security_defaults_properties" {
  value       = try(msgraph_update_resource.entra_security_defaults_update[0].output.all, null)
  description = "The tenant security defaults properties."
}

output "authentication_method_policy_microsoft_authenticator" {
  value       = msgraph_update_resource.entra_authentication_method_policy_microsoft_authenticator_update.output.all
  description = "The tenant's Microsoft Authenticator authentication method confiugration."
}

output "authentication_method_policy_email" {
  value       = msgraph_update_resource.entra_authentication_method_policy_email_update.output.all
  description = "The tenant's email authentication method confiugration."
}

output "authentication_methods_policy_fido2" {
  value       = msgraph_update_resource.entra_authentication_method_policy_fido2_update.output.all
  description = "The tenant's FIDO2 authentication method confiugration."
}

output "authentication_method_policy_software_oath" {
  value       = msgraph_update_resource.entra_authentication_method_policy_software_oath_update.output.all
  description = "The tenant's software OATH authentication method confiugration."
}
