# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

A Terraform module (not a deployable root config) that configures a Microsoft Entra ID tenant via the
[Microsoft Graph Terraform provider](https://registry.terraform.io/providers/microsoft/msgraph/latest/docs)
(`msgraph_resource`, `msgraph_update_resource`, `msgraph_resource_action`, `msgraph_resource` data source). It
automates organization settings, the authorization policy, security defaults, authentication methods policies
(email OTP, FIDO2, Microsoft Authenticator, software OATH), and custom domains, aiming to encode Microsoft's
[Entra ID best practices](https://learn.microsoft.com/en-us/entra/architecture/secure-best-practices). The module
is an MVP under active development — see the feature checklist in README.md for what's implemented vs. planned.

## Commands

Requires `terraform >= 1.9, < 2.0` and the `msgraph` provider `>= 0.3.0`.

```sh
terraform init
terraform fmt -recursive          # format
terraform validate                # validate
terraform test                    # run all tests in tests/
terraform test -filter=tests/organization.tftest.hcl   # run a single test file
```

Pre-commit hooks (`.pre-commit-config.yaml`) run `terraform_fmt`, `terraform_validate`, and `terraform_docs` on
commit — `terraform_docs` regenerates the `<!-- BEGIN_TF_DOCS -->...<!-- END_TF_DOCS -->` block in README.md from
`variable`/`output` descriptions, `_header.md`, and `_footer.md` (config in `.terraform-docs.yml`). **Do not
hand-edit the generated block in README.md** — edit variable/output descriptions in the `.tf` files, `_header.md`,
or `_footer.md` instead, then run `terraform-docs -c .terraform-docs.yml .` (or let pre-commit do it) to
regenerate.

## Testing conventions

Tests live in `tests/*.tftest.hcl` and use Terraform's native test framework with a mocked provider — no real
Entra ID tenant or network calls are involved:

```hcl
mock_provider "msgraph" {
  mock_resource "msgraph_update_resource" {
    defaults = { url = "organization/11111111-2222-3333-4444-555555555555" }
  }
}

run "test_preferred_language" {
  command = apply
  assert {
    condition     = msgraph_update_resource.entra_organization_update.body.preferredLanguage == var.organization_configuration.language
    error_message = "..."
  }
}
```

Assertions check the request `body` built by each resource, not real API responses. One `.tftest.hcl` file per
feature area, generally mirroring the resources in `main.tf` and `domains.tf` (organization, authorization_policy,
security_defaults, domains, authentication_methods_policy_*).

`tests/tests.tfvars` supplies a fixed fake `tenant_id` and is the one `.tfvars` file **not** excluded by
`.gitignore` (all other `*.tfvars` files are gitignored as they may hold real tenant IDs/secrets — this includes
the local `test.auto.tfvars` used for manual `terraform apply` against a real dev tenant).

## Architecture

- **`main.tf`** — core tenant-wide resources: organization properties, authorization policy, security defaults,
  and the four authentication method policies (Microsoft Authenticator, email, FIDO2, software OATH). Each is a
  single `msgraph_update_resource` (PATCH-style) targeting a fixed Graph API path (e.g.
  `policies/authenticationMethodsPolicy/authenticationMethodConfigurations/fido2`), translating snake_case
  Terraform variables into the camelCase Graph API body.
- **`data.tf`** — Terraform data sources
- **`domains.tf`** — custom domain lifecycle. Domain creation (`msgraph_resource.domains`) and the
  password policy update (`msgraph_update_resource.domain_password_policy`) are **separate resources** because
  the Graph API domain-create endpoint rejects the password-policy fields in the same request — the password
  policy update has an explicit `depends_on` to enforce ordering. Domain verification
  (`msgraph_resource_action.domain_verify`) only fires for domains with `trigger_verify_action = true` that are
  not yet verified (checked via `local.domain_detail`, sourced from the `data.msgraph_resource.domains` data
  source). `data.msgraph_resource.domain_verification_records` fetches DNS records for any unverified domain so
  callers can retrieve the records needed to complete verification out-of-band.
- **`locals.tf`** — static lookup tables (guest role GUIDs, permission-grant-policy lists) and tenant license-level
  detection: derives `Free`/`P1`/`P2` from `data.msgraph_resource.subscribed_skus` by checking for known Entra ID
  P1/P2 service plan GUIDs.
- **`variables.tf`** — inputs use nested `object({...optional(...)...})` types with in-Terraform `validation`
  blocks (e.g. email regex, ISO 3166 country code regex, URL prefix/length) rather than relying on the Graph API
  to reject bad input. Complex settings (organization config, auth methods policy, domains) are grouped into
  single object variables rather than many flat variables — follow this pattern for new grouped settings.
  Variable/output descriptions here are the source of truth for the generated docs in README.md.
- **`outputs.tf`** — mostly passes through each `msgraph_update_resource.*.output.all` (wrapped in `try(...,
  null)` since some resources are conditional, e.g. `security_defaults_properties` reads
  `entra_security_defaults_update[0]`).

### Working with the msgraph provider

- `msgraph_update_resource` bodies must mirror the Graph API's camelCase JSON schema exactly (see the Graph API
  docs linked in comments above each resource) — Terraform variables stay snake_case and are mapped explicitly.
- `response_export_values = { "all" = "@" }` is the established convention for exposing the full API response
  object on every `msgraph_update_resource`/data source in this module; follow it for new resources so outputs
  stay consistent.
- Some Graph API resources require multiple API calls that cannot be combined (see the domain password policy
  note above) — check whether a new Graph endpoint has similar restrictions before combining fields into one
  resource body.
- Remember Graph API's *eventual consistency* model (noted in README.md limitations): a resource created/updated
  in one `apply` may not be immediately readable by a dependent data source; use `depends_on` where ordering
  matters, as done for the domain password policy.
