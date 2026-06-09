locals {
  # Constants for guest access permissions
  # see https://learn.microsoft.com/en-us/entra/identity/users/users-restrict-guest-permissions
  guest_user_role_id = {
    user                = "a0b1b346-4d3e-4e8b-98f8-753987be4970"
    guestUser           = "10dae51f-b6af-4016-8d66-8c2a99b929b3"
    restrictedGuestUser = "2af84b1e-32c8-42b7-82bc-daa82404023b"
  }

  permission_grant_policies_assigned_with_user_consent = concat(
    var.permission_grant_policies_assigned,
    [
      "ManagePermissionGrantsForSelf.microsoft-user-default-allow-consent-apps",
      "ManagePermissionGrantsForSelf.microsoft-user-default-recommended",
    ]
  )

  domain_detail = { for key, domain in try(data.msgraph_resource.domains.output.all.value, {}) : domain.id => domain }

  # Calculate tenant license level based on service plans in the subscribed SKUs
  tenant_service_plan_ids = flatten([
    for sku in flatten(try(data.msgraph_resource.subscribed_skus.output.service_plans, [])) : sku.servicePlanId
  ])
  tenant_has_p1_license = contains(local.tenant_service_plan_ids, "41781fb2-bc02-4b7c-bd55-b576c07bb09d")
  tenant_has_p2_license = contains(local.tenant_service_plan_ids, "eec0eb4f-6444-4f95-aba0-50c24d67f998")
  tenant_license_level  = local.tenant_has_p2_license ? "P2" : (local.tenant_has_p1_license ? "P1" : "Free")
}
