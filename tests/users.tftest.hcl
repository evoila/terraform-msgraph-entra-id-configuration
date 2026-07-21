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

# Test case: a plain user create with only required fields
run "test_user_create_minimal" {
  command = plan

  variables {
    users = {
      jane = {
        user_principal_name = "jane.doe@contoso.com"
        display_name        = "Jane Doe"
        mail_nickname       = "jane.doe"
      }
    }
    user_passwords = {
      jane = {
        password = "P@ssw0rd1234!"
      }
    }
  }

  assert {
    condition     = msgraph_resource.users["jane"].body.userPrincipalName == "jane.doe@contoso.com"
    error_message = "The user's userPrincipalName must match the configured value."
  }

  assert {
    condition     = msgraph_resource.users["jane"].body.accountEnabled == true
    error_message = "A user must have accountEnabled = true by default."
  }

  assert {
    condition     = msgraph_resource.users["jane"].body.passwordProfile.forceChangePasswordNextSignIn == true
    error_message = "force_change_password_next_sign_in must default to true."
  }

  assert {
    condition     = jsonencode(msgraph_resource.users["jane"].body.businessPhones) == jsonencode([])
    error_message = "businessPhones must be an empty list when business_phone is not set."
  }
}

# Test case: a user create with all optional attributes populated
run "test_user_create_full" {
  command = plan

  variables {
    users = {
      john = {
        user_principal_name                = "john.smith@contoso.com"
        display_name                       = "John Smith"
        mail_nickname                      = "john.smith"
        given_name                         = "John"
        surname                            = "Smith"
        job_title                          = "Engineer"
        department                         = "Engineering"
        employee_id                        = "12345"
        mobile_phone                       = "+1 555 0100"
        business_phone                     = "+1 555 0199"
        other_mails                        = ["john.smith.alt@contoso.com"]
        usage_location                     = "US"
        account_enabled                    = false
        force_change_password_next_sign_in = false
      }
    }
    user_passwords = {
      john = {
        password = "P@ssw0rd1234!"
      }
    }
  }

  assert {
    condition     = msgraph_resource.users["john"].body.accountEnabled == false
    error_message = "accountEnabled must match the configured value."
  }

  assert {
    condition     = jsonencode(msgraph_resource.users["john"].body.businessPhones) == jsonencode(["+1 555 0199"])
    error_message = "businessPhones must wrap the configured business_phone into a single-element list."
  }

  assert {
    condition     = msgraph_resource.users["john"].body.usageLocation == "US"
    error_message = "usageLocation must match the configured value."
  }

  assert {
    condition     = msgraph_resource.users["john"].body.passwordProfile.forceChangePasswordNextSignIn == false
    error_message = "force_change_password_next_sign_in must match the configured value."
  }
}

# Test case: role assignment resolves the correct roleDefinitionId
run "test_user_role_assignment" {
  command = plan

  variables {
    users = {
      jane = {
        user_principal_name = "jane.doe@contoso.com"
        display_name        = "Jane Doe"
        mail_nickname       = "jane.doe"
        assigned_roles      = ["User Administrator"]
      }
    }
    user_passwords = {
      jane = {
        password = "P@ssw0rd1234!"
      }
    }
  }

  assert {
    condition     = msgraph_resource.user_role_assignments["jane:User Administrator"].body.roleDefinitionId == "fe930be7-5e62-47db-91af-98c3a49a38b1"
    error_message = "The role assignment must resolve to the correct built-in role template ID."
  }

  assert {
    condition     = msgraph_resource.user_role_assignments["jane:User Administrator"].body.directoryScopeId == "/"
    error_message = "Role assignments created by this module must be tenant-wide scoped."
  }
}

# Test case: a user without a matching var.user_passwords entry gets a random password auto-generated
run "test_auto_generated_password_for_missing_entry" {
  command = apply

  variables {
    users = {
      missing = {
        user_principal_name = "missing.password@contoso.com"
        display_name        = "Missing Password"
        mail_nickname       = "missing-password"
      }
      explicit = {
        user_principal_name = "explicit.password@contoso.com"
        display_name        = "Explicit Password"
        mail_nickname       = "explicit-password"
      }
    }
    user_passwords = {
      explicit = {
        password = "P@ssw0rd1234!"
      }
    }
  }

  assert {
    condition     = msgraph_resource.users["missing"].body.passwordProfile.password == random_password.user["missing"].result
    error_message = "A user without a matching user_passwords entry must get an auto-generated random password."
  }

  assert {
    condition     = length(random_password.user["missing"].result) == 24
    error_message = "The auto-generated password must be 24 characters long."
  }

  assert {
    condition     = !contains(keys(random_password.user), "explicit")
    error_message = "No random password should be generated for a user with an explicit user_passwords entry."
  }

  assert {
    condition     = msgraph_resource.users["explicit"].body.passwordProfile.password == "P@ssw0rd1234!"
    error_message = "A user with an explicit user_passwords entry must use that password, not a generated one."
  }
}

# Test case: variable validation blocks should reject invalid input at plan time
run "invalid_user_principal_name" {
  command = plan

  variables {
    users = {
      invalid = {
        user_principal_name = "not-a-upn"
        display_name        = "Invalid User"
        mail_nickname       = "invalid-user"
      }
    }
    user_passwords = {
      invalid = {
        password = "P@ssw0rd1234!"
      }
    }
  }

  expect_failures = [
    var.users,
  ]
}

run "invalid_mail_nickname" {
  command = plan

  variables {
    users = {
      invalid = {
        user_principal_name = "invalid.user@contoso.com"
        display_name        = "Invalid User"
        mail_nickname       = "invalid nickname@domain"
      }
    }
    user_passwords = {
      invalid = {
        password = "P@ssw0rd1234!"
      }
    }
  }

  expect_failures = [
    var.users,
  ]
}

run "invalid_usage_location" {
  command = plan

  variables {
    users = {
      invalid = {
        user_principal_name = "invalid.user@contoso.com"
        display_name        = "Invalid User"
        mail_nickname       = "invalid-user"
        usage_location      = "USA"
      }
    }
    user_passwords = {
      invalid = {
        password = "P@ssw0rd1234!"
      }
    }
  }

  expect_failures = [
    var.users,
  ]
}

run "invalid_empty_password" {
  command = plan

  variables {
    users = {
      invalid = {
        user_principal_name = "invalid.user@contoso.com"
        display_name        = "Invalid User"
        mail_nickname       = "invalid-user"
      }
    }
    user_passwords = {
      invalid = {
        password = ""
      }
    }
  }

  expect_failures = [
    var.user_passwords,
  ]
}

run "invalid_assigned_role" {
  command = plan

  variables {
    users = {
      invalid = {
        user_principal_name = "invalid.user@contoso.com"
        display_name        = "Invalid User"
        mail_nickname       = "invalid-user"
        assigned_roles      = ["Not A Real Role"]
      }
    }
    user_passwords = {
      invalid = {
        password = "P@ssw0rd1234!"
      }
    }
  }

  expect_failures = [
    var.users,
  ]
}
