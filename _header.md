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
- ✅ Configure [custom domains](https://learn.microsoft.com/en-us/graph/api/resources/domain)

> **NOTICE**
>
> - ✅ feature is implemented
> - 🟦 feature is partially implemented (e.g. not all MS graph properties exposed yet)
> - 🔲 feature will be implemented in a future release

## Limitations

This module is under development and currently considered a [minimum viable product](https://en.wikipedia.org/wiki/Minimum_viable_product) (MVP). Please create an issue in the [module GitHub repository](https://github.com/evoila/terraform-msgraph-entra-id-configuration/issues) if you have feature requests.

> **IMPORTANT** Microsoft Graph uses an _eventual consistency_ model. This means, changes are not immediately visible after a write. See [designing for eventual consistency for Microsoft Entra](https://devblogs.microsoft.com/identity/designing-for-eventual-consistency-for-microsoft-entra/) for more details.
