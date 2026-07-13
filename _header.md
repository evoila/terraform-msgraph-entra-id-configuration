# Terraform MS Graph Entra ID configuration Module

This Terraform module is designed to simplify Entra ID tenant configuration, including organization settings, policies, custom domains and more. It is intended to automate Microsoft's [Entra ID best practices configuration](https://learn.microsoft.com/en-us/entra/architecture/secure-best-practices).

## Features

- ✅ Configure basic [organization settings](https://learn.microsoft.com/en-us/graph/api/resources/organization).
- 🟦 Configure the [authorization policy](https://learn.microsoft.com/en-us/graph/api/resources/authorizationpolicy).
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
