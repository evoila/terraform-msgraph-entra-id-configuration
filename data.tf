# Get all configured domains
data "msgraph_resource" "domains" {
  url = "domains"
  response_export_values = {
    all = "@"
    id  = "id"
  }
}

# Get DNS verification records for all unverified domains
data "msgraph_resource" "domain_verification_records" {
  for_each = toset([for domain in try(data.msgraph_resource.domains.output.all.value, {}) : domain.id if domain.isVerified == false])

  url = "domains/${each.value}/verificationDnsRecords"
  response_export_values = {
    all = "@"
  }
}

# Get tenant's SKU service plans
# see https://learn.microsoft.com/en-us/entra/identity/users/licensing-service-plan-reference
data "msgraph_resource" "subscribed_skus" {
  url = "subscribedSkus"
  response_export_values = {
    service_plans = "value[].servicePlans"
  }
}
