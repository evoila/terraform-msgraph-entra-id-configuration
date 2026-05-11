locals {
  # Constants for guest access permissions
  # see https://learn.microsoft.com/en-us/entra/identity/users/users-restrict-guest-permissions
  guest_user_role_id = {
    user                = "a0b1b346-4d3e-4e8b-98f8-753987be4970"
    guestUser           = "10dae51f-b6af-4016-8d66-8c2a99b929b3"
    restrictedGuestUser = "2af84b1e-32c8-42b7-82bc-daa82404023b"
  }

  # Disallow user consent to applications
  permission_grant_policies_assigned_strict = [
    "ManagePermissionGrantsForOwnedResource.microsoft-dynamically-managed-permissions-for-chat",
    "ManagePermissionGrantsForOwnedResource.microsoft-dynamically-managed-permissions-for-team"
  ]

  # Disallow user consent to applications
  permission_grant_policies_assigned_relaxed = [
    "ManagePermissionGrantsForOwnedResource.microsoft-dynamically-managed-permissions-for-chat",
    "ManagePermissionGrantsForOwnedResource.microsoft-dynamically-managed-permissions-for-team",
    "ManagePermissionGrantsForSelf.microsoft-user-default-allow-consent-apps",
    "ManagePermissionGrantsForSelf.microsoft-user-default-recommended",
  ]

  permission_grant_policies_assigned_with_user_consent = concat(
    var.permission_grant_policies_assigned,
    [
      "ManagePermissionGrantsForSelf.microsoft-user-default-allow-consent-apps",
      "ManagePermissionGrantsForSelf.microsoft-user-default-recommended",
    ]
  )
}
