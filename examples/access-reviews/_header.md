# Access reviews example

This example configures two access reviews: a recurring quarterly review of a group's membership, and a one-time review of Global Administrator role assignments.

**WARNING**: Access reviews require an Entra ID P2 or Governance license - this module silently skips creating them if the tenant doesn't have one.

> **Note**
>
> Access reviews can use complex MS Graph queries - to allow easier configuration, this module supplies templates for common use-cases. See [/templates/README.md](/templates/README.md) for more information.
