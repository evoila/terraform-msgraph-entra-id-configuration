locals {
  # Constants for guest access permissions
  # see https://learn.microsoft.com/en-us/entra/identity/users/users-restrict-guest-permissions
  guest_user_role_id = {
    user                = "a0b1b346-4d3e-4e8b-98f8-753987be4970"
    guestUser           = "10dae51f-b6af-4016-8d66-8c2a99b929b3"
    restrictedGuestUser = "2af84b1e-32c8-42b7-82bc-daa82404023b"
  }

  # Curated subset of built-in Entra ID role template IDs, keyed by their display name.
  # see https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference
  # Not exhaustive - extend as needed.
  directory_role_template_id = {
    "Global Administrator"            = "62e90394-69f5-4237-9190-012177145e10"
    "Privileged Role Administrator"   = "e8611ab8-c189-46e8-94e1-60213ab1f814"
    "User Administrator"              = "fe930be7-5e62-47db-91af-98c3a49a38b1"
    "Helpdesk Administrator"          = "729827e3-9c14-49f7-bb1b-9608f156bbb8"
    "Password Administrator"          = "966707d0-3269-4727-9be2-8c3a10f19b9d"
    "Authentication Administrator"    = "c4e39bd9-1100-46d3-8c65-fb160da0071f"
    "Groups Administrator"            = "fdd7a751-b60b-444a-984c-02652fe8fa1c"
    "Application Administrator"       = "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"
    "Cloud Application Administrator" = "158c047a-c907-4556-b7ef-446551a6b5f7"
    "Security Administrator"          = "194ae4cb-b126-40b2-bd5b-6091b380977d"
    "Security Reader"                 = "5d6b6bb7-de71-4623-b4af-96380a352509"
    "Global Reader"                   = "f2ef992c-3afb-46b9-b7cf-a126ee74c451"
  }

  permission_grant_policies_assigned_with_user_consent = concat(
    var.permission_grant_policies_assigned,
    [
      "ManagePermissionGrantsForSelf.microsoft-user-default-allow-consent-apps",
      "ManagePermissionGrantsForSelf.microsoft-user-default-recommended",
    ]
  )

  # Calculate tenant license level based on service plans in the subscribed SKUs
  tenant_service_plan_ids = flatten([
    for sku in flatten(try(data.msgraph_resource.subscribed_skus.output.service_plans, [])) : sku.servicePlanId
  ])
  tenant_has_p1_license = contains(local.tenant_service_plan_ids, "41781fb2-bc02-4b7c-bd55-b576c07bb09d")
  tenant_has_p2_license = contains(local.tenant_service_plan_ids, "eec0eb4f-6444-4f95-aba0-50c24d67f998")
  tenant_license_level  = local.tenant_has_p2_license ? "P2" : (local.tenant_has_p1_license ? "P1" : "Free")
}
