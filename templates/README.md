# Access review scope templates

This directory holds reusable Microsoft Graph [`accessReviewScope`](https://learn.microsoft.com/en-us/graph/api/resources/accessreviewscope)
JSON bodies for the `access_reviews` variable's `scope` and `instance_enumeration_scope` fields
(see `access_reviews.tf` / `variables.tf` in the module root). Each file is a `.tftpl.json`
template rendered via Terraform's `templatefile()` function and decoded with `jsondecode()`
directly into the resource body — so a template can express any Graph scope shape (including the
polymorphic `principalResourceMembershipsScope` and `accessReviewInactiveUsersQueryScope` variants)
without the module's variable type needing to model them.

To use a template, set `template` to the file's base name (no extension) and provide any required
values via `template_vars`:

```hcl
access_reviews = {
  marketing_group_review = {
    display_name              = "Marketing group access review"
    description_for_reviewers = "Quarterly review of Marketing group membership"
    scope = {
      template      = "users_assigned_to_group"
      template_vars = { group_id = "11111111-2222-3333-4444-555555555555" }
    }
    settings = {
      recurrence = {
        range = { start_date = "2026-01-01" }
      }
    }
  }
}
```

`template` and `query` are mutually exclusive — set exactly one. Templates with no `${...}`
placeholders (see tables below) can omit `template_vars` entirely (it defaults to `{}`).

## Access review scopes

Templates for the `scope` attribute, defining who/what is reviewed.

| Template                                      | OData type                            | Parameters                      | Description                                                                                                                                                                                                                                                         |
| --------------------------------------------- | ------------------------------------- | ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `users_assigned_to_group`                     | `accessReviewQueryScope`              | `group_id`                      | All (transitive) members of a group.                                                                                                                                                                                                                                |
| `users_directly_assigned_to_group`            | `accessReviewQueryScope`              | `group_id`                      | Only direct members of a group (no transitive/nested membership).                                                                                                                                                                                                   |
| `guest_users_assigned_to_group`               | `accessReviewQueryScope`              | `group_id`                      | Guest (B2B) members of a group.                                                                                                                                                                                                                                     |
| `inactive_users_assigned_to_group`            | `accessReviewInactiveUsersQueryScope` | `group_id`, `inactive_duration` | Members of a group who have been inactive for at least `inactive_duration` (ISO-8601 duration, e.g. `P30D`).                                                                                                                                                        |
| `users_assigned_to_role`                      | `accessReviewQueryScope`              | `role_id`                       | All principals (active and eligible) assigned a directory role.                                                                                                                                                                                                     |
| `guest_users_assigned_to_role`                | `principalResourceMembershipsScope`   | `role_id`                       | Guest users assigned a directory role.                                                                                                                                                                                                                              |
| `service_principals_assigned_to_role`         | `accessReviewQueryScope`              | `role_id`                       | Service principals assigned a directory role.                                                                                                                                                                                                                       |
| `users_assigned_to_application`               | `principalResourceMembershipsScope`   | `service_principal_id`          | All users and group members with access to an application/service principal.                                                                                                                                                                                        |
| `guest_users_assigned_to_teams`               | `accessReviewQueryScope`              | _(none)_                        | Guest members of a Team. Relative query (`./members/...`) — use only as `scope` together with an `instance_enumeration_scope` (e.g. `any_teams`) that enumerates the Teams to review; no `queryRoot` is needed since the query is resolved per enumerated instance. |
| `users_directly_assigned_to_m365_group`       | `accessReviewQueryScope`              | _(none)_                        | Direct members of an M365 group. Relative query — same pairing requirement as `guest_users_assigned_to_teams` above (typically with `any_m365_group`).                                                                                                              |
| `users_assigned_to_team_including_b2b`        | `principalResourceMembershipsScope`   | `group_id`                      | All users (including B2B guests) with access to a Team, via its members and shared channels.                                                                                                                                                                        |
| `inactive_guest_users_assigned_to_m365_group` | `accessReviewInactiveUsersQueryScope` | `inactive_duration`             | Inactive guest members of an M365 group. Relative query — pair with `any_m365_group` as `instance_enumeration_scope`.                                                                                                                                               |
| `inactive_guest_users_assigned_to_teams`      | `accessReviewInactiveUsersQueryScope` | `inactive_duration`             | Inactive guest members of a Team. Relative query — pair with `any_teams` as `instance_enumeration_scope`.                                                                                                                                                           |

## Instance enumeration scopes

Templates for the `instance_enumeration_scope` attribute, used for "all groups"/"all teams" style
reviews where a separate review instance is created per enumerated resource. Pair these with one
of the relative-query `scope` templates above (or a custom relative `query`).

| Template         | Parameters | Description                                                                       |
| ---------------- | ---------- | --------------------------------------------------------------------------------- |
| `any_m365_group` | _(none)_   | Enumerates all Microsoft 365 (unified) groups in the tenant.                      |
| `any_teams`      | _(none)_   | Enumerates all Microsoft Teams (M365 groups provisioned as a Team) in the tenant. |

## Additional Graph resource type documentation

- [accessReviewQueryScope](https://learn.microsoft.com/en-us/graph/api/resources/accessreviewqueryscope?view=graph-rest-1.0) resource type
- [accessReviewInactiveUsersQueryScope](https://learn.microsoft.com/en-us/graph/api/resources/accessreviewinactiveusersqueryscope?view=graph-rest-1.0) resource type
- [principalResourceMembershipsScope](https://learn.microsoft.com/en-us/graph/api/resources/principalresourcemembershipsscope?view=graph-rest-1.0) resource type
