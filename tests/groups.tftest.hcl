variables {
  tenant_id = "11111111-2222-3333-4444-555555555555"
  organization_configuration = {
    notification_email = "jane.doe@contoso.com"
  }
}

mock_provider "msgraph" {
  mock_data "msgraph_resource" {
    defaults = {
      output = {
        all           = { value = [] }
        service_plans = []
      }
    }
  }
}

# Test case: a plain assigned-membership security group
run "test_security_group_create" {
  command = plan

  variables {
    groups = {
      security_group = {
        display_name  = "Test Security Group"
        mail_nickname = "test-security-group"
      }
    }
  }

  assert {
    condition     = msgraph_resource.groups["security_group"].body.displayName == "Test Security Group"
    error_message = "The group's displayName must match the configured display_name."
  }

  assert {
    condition     = msgraph_resource.groups["security_group"].body.securityEnabled == true
    error_message = "A security group must have securityEnabled = true by default."
  }

  assert {
    condition     = msgraph_resource.groups["security_group"].body.mailEnabled == false
    error_message = "A plain security group must have mailEnabled = false by default."
  }

  assert {
    condition     = jsonencode(msgraph_resource.groups["security_group"].body.groupTypes) == jsonencode([])
    error_message = "A plain security group must have an empty groupTypes list."
  }
}

# Test case: an assigned-membership Microsoft 365 (Unified) group
run "test_m365_group_create" {
  command = plan

  variables {
    groups = {
      m365_group = {
        display_name  = "Test M365 Group"
        mail_nickname = "test-m365-group"
        mail_enabled  = true
        group_types   = ["Unified"]
        visibility    = "Private"
      }
    }
  }

  assert {
    condition     = msgraph_resource.groups["m365_group"].body.mailEnabled == true
    error_message = "A Microsoft 365 group must have mailEnabled = true."
  }

  assert {
    condition     = jsonencode(msgraph_resource.groups["m365_group"].body.groupTypes) == jsonencode(["Unified"])
    error_message = "A Microsoft 365 group must include \"Unified\" in groupTypes."
  }

  assert {
    condition     = msgraph_resource.groups["m365_group"].body.visibility == "Private"
    error_message = "The group's visibility must match the configured value."
  }
}

# Test case: a dynamic membership group requires an Entra ID P1 license
run "test_dynamic_membership_group" {
  command = apply

  variables {
    groups = {
      dynamic_group = {
        display_name    = "Test Dynamic Group"
        mail_nickname   = "test-dynamic-group"
        group_types     = ["DynamicMembership"]
        membership_rule = "(user.department -eq \"Sales\")"
      }
    }
  }

  override_data {
    target = data.msgraph_resource.subscribed_skus
    values = {
      output = {
        service_plans = [
          [
            { servicePlanId = "41781fb2-bc02-4b7c-bd55-b576c07bb09d" }, # Entra ID P1
          ],
        ]
      }
    }
  }

  assert {
    condition     = msgraph_update_resource.group_membership_rule["dynamic_group"].body.membershipRule == "(user.department -eq \"Sales\")"
    error_message = "The group's dynamic membership rule must match the configured value."
  }

  assert {
    condition     = msgraph_update_resource.group_membership_rule["dynamic_group"].body.membershipRuleProcessingState == "On"
    error_message = "The group's membership rule processing state must default to 'On'."
  }

  assert {
    condition     = !contains(keys(msgraph_resource_collection.group_members), "dynamic_group")
    error_message = "No members collection should be reconciled for a dynamic membership group."
  }
}

# Test case: dynamic membership groups must not be configurable without an Entra ID P1 license
run "test_dynamic_membership_without_p1_license_fails" {
  command = plan

  variables {
    groups = {
      dynamic_group = {
        display_name    = "Test Dynamic Group"
        mail_nickname   = "test-dynamic-group"
        group_types     = ["DynamicMembership"]
        membership_rule = "(user.department -eq \"Sales\")"
      }
    }
  }

  expect_failures = [
    msgraph_update_resource.group_membership_rule,
  ]
}

# Test case: owners and members are reconciled via msgraph_resource_collection
run "test_group_owners_and_members_attachment" {
  command = plan

  variables {
    groups = {
      with_membership = {
        display_name  = "Test Group With Membership"
        mail_nickname = "test-group-with-membership"
        owners        = ["11111111-1111-1111-1111-111111111111"]
        members = [
          "22222222-2222-2222-2222-222222222222",
          "33333333-3333-3333-3333-333333333333",
        ]
      }
      without_membership = {
        display_name  = "Test Group Without Membership"
        mail_nickname = "test-group-without-membership"
      }
    }
  }

  assert {
    condition     = msgraph_resource_collection.group_owners["with_membership"].reference_ids == var.groups["with_membership"].owners
    error_message = "The group's owners collection must match the configured owners list."
  }

  assert {
    condition     = msgraph_resource_collection.group_members["with_membership"].reference_ids == var.groups["with_membership"].members
    error_message = "The group's members collection must match the configured members list."
  }

  assert {
    condition     = !contains(keys(msgraph_resource_collection.group_owners), "without_membership")
    error_message = "No owners collection should be created for a group with no configured owners."
  }

  assert {
    condition     = !contains(keys(msgraph_resource_collection.group_members), "without_membership")
    error_message = "No members collection should be created for a group with no configured members."
  }
}

# Test case: properties that Microsoft Graph only allows setting at creation (groupTypes,
# mailEnabled, isAssignableToRole) must never be re-sent in a later PATCH, even if the caller
# changes them in configuration - Graph rejects such a request with a 400 Bad Request. This
# reproduces the two-apply sequence that failed in a real deployment: create a group, then apply
# again with those fields changed.
run "test_immutable_properties_frozen_after_creation" {
  command = apply

  variables {
    groups = {
      frozen = {
        display_name  = "Frozen Group"
        mail_nickname = "frozen-group"
        mail_enabled  = false
        group_types   = []
      }
    }
  }

  assert {
    condition     = msgraph_resource.groups["frozen"].body.mailEnabled == false
    error_message = "The group must be created with mailEnabled = false as configured."
  }
}

run "test_immutable_properties_frozen_after_creation_second_apply" {
  command = plan

  variables {
    groups = {
      frozen = {
        display_name  = "Frozen Group"
        mail_nickname = "frozen-group"
        mail_enabled  = true # attempt to flip a create-only property
        group_types   = ["Unified"]
      }
    }
  }

  assert {
    condition     = msgraph_resource.groups["frozen"].body.mailEnabled == false
    error_message = "mailEnabled must stay frozen at its original creation-time value and must not be re-planned, since Graph rejects it in a PATCH."
  }

  assert {
    condition     = jsonencode(msgraph_resource.groups["frozen"].body.groupTypes) == jsonencode([])
    error_message = "groupTypes must stay frozen at its original creation-time value and must not be re-planned, since Graph rejects it in a PATCH."
  }

  assert {
    condition     = msgraph_update_resource.groups_update["frozen"].body.displayName == "Frozen Group"
    error_message = "The groups_update resource must keep managing the properties Graph allows updating indefinitely."
  }
}

# Test case: variable validation blocks should reject invalid input at plan time
run "invalid_mail_nickname" {
  command = plan

  variables {
    groups = {
      invalid = {
        display_name  = "Invalid Group"
        mail_nickname = "invalid nickname@domain"
      }
    }
  }

  expect_failures = [
    var.groups,
  ]
}

run "invalid_group_types_combination" {
  command = plan

  variables {
    groups = {
      invalid = {
        display_name  = "Invalid Group"
        mail_nickname = "invalid-group"
        group_types   = ["NotARealType"]
      }
    }
  }

  expect_failures = [
    var.groups,
  ]
}

run "invalid_mail_enabled_without_unified" {
  command = plan

  variables {
    groups = {
      invalid = {
        display_name  = "Invalid Group"
        mail_nickname = "invalid-group"
        mail_enabled  = true
      }
    }
  }

  expect_failures = [
    var.groups,
  ]
}

run "invalid_membership_rule_without_dynamic_membership" {
  command = plan

  variables {
    groups = {
      invalid = {
        display_name    = "Invalid Group"
        mail_nickname   = "invalid-group"
        membership_rule = "(user.department -eq \"Sales\")"
      }
    }
  }

  expect_failures = [
    var.groups,
  ]
}

run "invalid_membership_rule_with_members" {
  command = plan

  variables {
    groups = {
      invalid = {
        display_name    = "Invalid Group"
        mail_nickname   = "invalid-group"
        group_types     = ["DynamicMembership"]
        membership_rule = "(user.department -eq \"Sales\")"
        members         = ["11111111-1111-1111-1111-111111111111"]
      }
    }
  }

  expect_failures = [
    var.groups,
  ]
}

run "invalid_is_assignable_to_role_without_security_enabled" {
  command = plan

  variables {
    groups = {
      invalid = {
        display_name          = "Invalid Group"
        mail_nickname         = "invalid-group"
        security_enabled      = false
        visibility            = "Private"
        is_assignable_to_role = true
      }
    }
  }

  expect_failures = [
    var.groups,
  ]
}
