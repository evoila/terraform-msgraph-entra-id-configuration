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
  for_each = toset([for domain in data.msgraph_resource.domains.output.all.value : domain.id if domain.isVerified == false])

  url = "domains/${each.value}/verificationDnsRecords"
  response_export_values = {
    all = "@"
  }
}
