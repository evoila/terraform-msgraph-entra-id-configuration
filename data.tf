data "msgraph_resource" "organization" {
  url = "organization"
  response_export_values = {
    id         = "value[0].id"
    properties = "value[0]"
  }
  depends_on = [msgraph_update_resource.entra_organization_update] # read organization AFTER it was updated
}

data "msgraph_resource" "authorization_policy" {
  url = "policies/authorizationPolicy"
  response_export_values = {
    properties = "@"
  }
}

# data "msgraph_resource" "entra_authentication_method_policy_fido2" {
#   url = "policies/authenticationMethodsPolicy/authenticationMethodConfigurations/fido2"
#   response_export_values = {
#     properties = "@"
#   }
# }
