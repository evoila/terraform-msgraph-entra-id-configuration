terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    msgraph = {
      source  = "microsoft/msgraph"
      version = "~> 0.3"
    }
  }
}

provider "msgraph" {}

module "entra" {
  source = "../../" # Replace with correct module path

  tenant_id = "11111111-2222-3333-4444-555555555555"

  organization_configuration = {
    notification_email     = "jane.doe@contoso.com"
    language               = "en"
    default_usage_location = "US"
  }

  # Emergency access ("break-glass") accounts, per Microsoft's recommendation to maintain at least
  # two cloud-only, highly privileged accounts that remain usable even if federated sign-in, MFA, or
  # Conditional Access is unavailable. See
  # https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/security-emergency-access.
  users = {
    breakglass1 = {
      user_principal_name = "breakglass1@contoso.onmicrosoft.com"
      display_name        = "BREAK GLASS - Emergency Access 1"
      mail_nickname       = "breakglass1"
      usage_location      = "US"
      assigned_roles      = ["Global Administrator"]

      # Break-glass credentials must stay static and known, so the account is not forced to
      # change its password on first sign-in.
      force_change_password_next_sign_in = false
    }
    breakglass2 = {
      user_principal_name = "breakglass2@contoso.onmicrosoft.com"
      display_name        = "BREAK GLASS - Emergency Access 2"
      mail_nickname       = "breakglass2"
      usage_location      = "US"
      assigned_roles      = ["Global Administrator"]

      force_change_password_next_sign_in = false
    }
  }

  # Initial passwords for the accounts above, supplied explicitly (rather than left to be
  # auto-generated) because break-glass credentials need to be printed/sealed and stored in a
  # secure physical location per Microsoft's guidance, which requires knowing them up front.
  user_passwords = {
    breakglass1 = {
      password = "..." # supply via a secrets-managed .tfvars or pipeline variable. Never commit this!
    }
    breakglass2 = {
      password = "..." # supply via a secrets-managed .tfvars or pipeline variable. Never commit this!
    }
  }

  # A group used to exclude the break-glass accounts from Conditional Access policies - Microsoft
  # explicitly recommends excluding emergency access accounts from CA, since they must remain
  # usable even if CA/MFA infrastructure itself is unavailable or misconfigured.
  groups = {
    breakglass_accounts = {
      display_name  = "Break Glass Accounts"
      mail_nickname = "breakglass-accounts"
      description   = "Emergency access accounts, excluded from all Conditional Access policies."
      members       = [module.entra.user_ids["breakglass1"], module.entra.user_ids["breakglass2"]]
    }
  }
}

# Object IDs of the created break-glass accounts. Add these to `breakglass_group_member_ids` and
# apply again to add the accounts as members of the "Break Glass Accounts" group.
output "breakglass_account_ids" {
  value = module.entra.user_ids
}

# Object ID of the "Break Glass Accounts" group, to exclude from Conditional Access policies.
output "breakglass_accounts_group_id" {
  value = module.entra.group_ids["breakglass_accounts"]
}
