# Terraform MS Graph Entra ID configuration Module

This Terraform module is designed to simplify Entra ID tenant configuration, including organization settings, policies, custom domains and more. It is intended to automate Microsoft's [Entra ID best practices configuration](https://learn.microsoft.com/en-us/entra/architecture/secure-best-practices).

## Features

- ✅ Configure basic [organization settings](https://learn.microsoft.com/en-us/graph/api/resources/organization).
- 🟦 Configure [users](https://learn.microsoft.com/en-us/graph/api/resources/user) (create/update, built-in Entra role assignment). See below for current limitations.
- 🟦 Configure [groups](https://learn.microsoft.com/en-us/graph/api/resources/group) (security and Microsoft 365 groups, including dynamic membership) and their owners/members. See below for current limitations.
- ✅ Configure the [authorization policy](https://learn.microsoft.com/en-us/graph/api/resources/authorizationpolicy).
- ✅ Enable or disable [security defaults](https://learn.microsoft.com/en-us/entra/fundamentals/security-defaults).
- Configure [authentication methods policies](https://learn.microsoft.com/en-us/graph/api/resources/authenticationmethodspolicies-overview):
  - ✅ [Email](https://learn.microsoft.com/en-us/graph/api/resources/emailauthenticationmethodconfiguration)
  - 🔲 [External MFA](https://learn.microsoft.com/en-us/graph/api/resources/externalauthenticationmethodconfiguration)
  - ✅ [FIDO2](https://learn.microsoft.com/en-us/graph/api/resources/fido2authenticationmethodconfiguration)
  - ✅ [Microsoft Authenticator](https://learn.microsoft.com/en-us/graph/api/resources/microsoftauthenticatorauthenticationmethodconfiguration)
  - 🔲 [QR code pin](https://learn.microsoft.com/en-us/graph/api/resources/qrcodepinauthenticationmethodconfiguration)
  - 🔲 [SMS](https://learn.microsoft.com/en-us/graph/api/resources/smsauthenticationmethodconfiguration)
  - 🔲 [Temporary Access Pass](https://learn.microsoft.com/en-us/graph/api/resources/temporaryaccesspassauthenticationmethodconfiguration) (TAP)
  - ✅ [Software OATH](https://learn.microsoft.com/en-us/graph/api/resources/softwareoathauthenticationmethodconfiguration)
  - 🔲 [Verifiable credentials](https://learn.microsoft.com/en-us/graph/api/resources/verifiablecredentialsauthenticationmethodconfiguration)
  - 🔲 [Voice](https://learn.microsoft.com/en-us/graph/api/resources/voiceauthenticationmethodconfiguration)
  - 🔲 [X509 certificate](https://learn.microsoft.com/en-us/graph/api/resources/voiceauthenticationmethodconfiguration)
- ✅ Configure [custom domains](https://learn.microsoft.com/en-us/graph/api/resources/domain).
- 🟦 Configure [access reviews](https://learn.microsoft.com/en-us/graph/api/resources/accessreviewsv2-overview). See below for current limitations.

> **NOTICE**
>
> - ✅ feature is implemented
> - 🟦 feature is partially implemented (e.g. not all MS graph properties exposed yet)
> - 🔲 feature will be implemented in a future release

## Limitations

This module is under development and currently considered a [minimum viable product](https://en.wikipedia.org/wiki/Minimum_viable_product) (MVP). Please create an issue in the [module GitHub repository](https://github.com/evoila/terraform-msgraph-entra-id-configuration/issues) if you have feature requests.

> **IMPORTANT** Microsoft Graph uses an _eventual consistency_ model. This means, changes are not immediately visible after a write. See [designing for eventual consistency for Microsoft Entra](https://devblogs.microsoft.com/identity/designing-for-eventual-consistency-for-microsoft-entra/) for more details.

## Configuring Groups

The module can create and manage [security groups and Microsoft 365 groups](https://learn.microsoft.com/en-us/graph/api/resources/group), including [dynamic membership groups](https://learn.microsoft.com/en-us/entra/identity/users/groups-dynamic-membership) via `membership_rule` (requires an Entra ID P1 or higher license). Group owners and members are referenced by their existing Entra ID object ID (GUID) - creating or managing the underlying users is out of scope for this module.

> **NOTE**
>
> - Group membership (`owners`/`members`) is fully reconciled on every `terraform apply`: object IDs removed from the list are removed from the group in Entra ID, and any added are added. If members are also managed by another process (for example manually, or via a dynamic membership rule), do not list them here to avoid Terraform reverting out-of-band changes.
> - Since owners are attached after group creation rather than at creation time, there is a brief window where a newly created group has no owner ("anonymously owned" in Microsoft Graph terms). Configure at least one owner for any group that needs to be manageable afterwards.

Here is an example of a security group and a dynamic Microsoft 365 group:

```hcl
groups = {
  engineering = {
    display_name  = "Engineering"
    mail_nickname = "engineering"
    group_types   = [] # plain security group
    owners        = ["11111111-2222-3333-4444-555555555555"]
    members = [
      "66666666-7777-8888-9999-000000000000",
      "77777777-8888-9999-0000-111111111111",
    ]
  }
  all_sales = {
    display_name    = "All Sales (dynamic)"
    mail_nickname   = "all-sales"
    mail_enabled    = true
    group_types     = ["Unified", "DynamicMembership"]
    visibility      = "Private"
    membership_rule = "(user.department -eq \"Sales\")"
  }
}
```

The group's Entra ID object ID is exposed via the `group_ids` output and can be referenced from other resources configured by this module, for example to scope an [access review](#configuring-access-reviews) to the `engineering` group:

```hcl
access_reviews = {
  engineering_review = {
    # ...
    scope = {
      template = "users_assigned_to_group"
      template_vars = {
        group_id = module.entra.group_ids["engineering"]
      }
    }
  }
}
```

or to scope an authentication method policy (for example FIDO2) to a managed group:

```hcl
authentication_methods_policy_configuration = {
  fido2 = {
    included_groups = [module.entra.group_ids["engineering"]]
  }
}
```

## Configuring Users

The module can create and manage [users](https://learn.microsoft.com/en-us/graph/api/resources/user) and assign
them a curated set of built-in Entra ID directory roles, tenant-wide. Its **primary use-cases** are onboarding of initial tenant admin accounts and the creation of [emergency access (break-glass) accounts](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/security-emergency-access). Use the official [Hashicorp AzureAD Terraform provider](https://registry.terraform.io/providers/hashicorp/azuread/) if you require full user-management capabilities.

Initial passwords are supplied via the separate, sensitive `user_passwords` variable rather than `users` itself,
since sensitive values cannot be used in `for_each`. Any user without a matching entry in `user_passwords` gets a
random password auto-generated instead - the generated value is available (per user) via the `users_details`
output.

> **NOTE**
>
> - Adding module-created users to module-managed groups is not directly supported by the `users` variable. Add
>   the object ID (from the `user_ids` output) to the relevant entry's `members`/`owners` list in
>   [`groups`](#configuring-groups) on a subsequent `terraform apply` instead, the same way as for any pre-existing
>   user.
> - Role assignments are always tenant-wide scoped (`directoryScopeId = "/"`); administrative-unit-scoped role
>   assignments are not supported.

```hcl
users = {
  jane = {
    user_principal_name = "jane.doe@contoso.com"
    display_name        = "Jane Doe"
    mail_nickname       = "jane.doe"
    department          = "Engineering"
    usage_location       = "DE"
    assigned_roles       = ["User Administrator"]
  }
}

user_passwords = {
  jane = {
    password = "..." # supply via a secrets-managed .tfvars or pipeline variables. Never commit this!
  }
}
```

## Configuring the Authorization Policy

The [authorization policy](https://learn.microsoft.com/en-us/graph/api/resources/authorizationpolicy) controls
tenant-wide authorization settings such as external invitations, self-service password reset, the default guest
user role, and what regular users are allowed to do (create apps, tenants, security groups, or consent to
application permissions).

Here's an example of how to configure basic authorization policy properties:

```hcl
allow_invites_from                = "adminsAndGuestInviters" # Restrict who can invite external guests
allowed_to_use_sspr               = true                     # Allow users to reset their own password
guest_user_role                   = "restrictedGuestUser"    # Limit guest visibility into the directory
allowed_to_create_apps            = false                    # Prevent users from registering applications
allowed_to_create_tenants         = false                    # Prevent users from creating new tenants
allowed_to_create_security_groups = false                    # Prevent users from creating security groups
allow_user_apps_consent           = false                    # Require admin consent for application permissions
block_msol_powershell             = true                     # Block access to the deprecated MSOnline PowerShell module
```

## Configuring Access Reviews

The Module can currently create **single-stage** [Access Reviews](https://learn.microsoft.com/en-us/entra/id-governance/access-reviews-overview) only. Please also be aware that some Access Review features require a Microsoft Entra ID Governance or Microsoft Entra Suite license. See [License requirements](https://learn.microsoft.com/en-us/entra/id-governance/access-reviews-overview#license-requirements) for more details.

Access reviews are based on MS Graph queries, which can be quite complex. We have therefore provided a set of [query templates](./templates/README.md) for standard use-cases.

Here is an example of how to configure a one-time access review for group membership:

```hcl
access_reviews = {
  example_review = {
    display_name              = "Example Review U.S. Sales group"
    description_for_reviewers = "Please review if membership in the 'U.S. Sales' group is still required."
    description_for_admins    = "One-time self-review of U.S. Sales group membership."
    scope = {
      template = "users_assigned_to_group" # Using the template to check _any_ user assigned to a group
      template_vars = {
        group_id = "11111111-2222-3333-4444-555555555555" # specify the 'U.S. Sales' group object ID
      }
    }
    instance_enumeration_scope = {
      query = "/v1.0/groups/11111111-2222-3333-4444-555555555555" # scope the review to the 'U.S. Sales' group only
    }
    settings = {
      default_decision_enabled = true
      default_decision         = "Deny" # Remove users who did not complete the review from the group
      recurrence = { # Make this a one-time review in January 2026
        range = {
          start_date = "2026-01-01"
          end_date   = "2026-01-31"
          type       = "endDate"
        }
      }
    }
    additional_notification_recipients = [{
      notification_recipient_scope = {
        query = "/v1.0/users/66666666-7777-8888-9999-000000000000" # Object ID of a specific user to receive notifications in case the target group does not have an owner
      }
    }]
  }
}
```
