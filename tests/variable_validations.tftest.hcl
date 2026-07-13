# Test case: variable validation blocks should reject invalid input at plan time.
variables {
  tenant_id = "11111111-2222-3333-4444-555555555555"
  organization_configuration = {
    notification_email = "jane.doe@contoso.com"
  }
}

mock_provider "msgraph" {}

run "invalid_notification_email" {
  command = plan

  variables {
    organization_configuration = {
      notification_email = "not-an-email"
    }
  }

  expect_failures = [
    var.organization_configuration,
  ]
}

run "invalid_default_usage_location" {
  command = plan

  variables {
    organization_configuration = {
      notification_email     = "jane.doe@contoso.com"
      default_usage_location = "USA" # must be a two-letter code
    }
  }

  expect_failures = [
    var.organization_configuration,
  ]
}

run "invalid_privacy_contact_email" {
  command = plan

  variables {
    organization_configuration = {
      notification_email    = "jane.doe@contoso.com"
      privacy_contact_email = "not-an-email"
    }
  }

  expect_failures = [
    var.organization_configuration,
  ]
}

run "invalid_privacy_statement_url" {
  command = plan

  variables {
    organization_configuration = {
      notification_email    = "jane.doe@contoso.com"
      privacy_statement_url = "ftp://contoso.com/privacy"
    }
  }

  expect_failures = [
    var.organization_configuration,
  ]
}

run "invalid_allow_invites_from" {
  command = plan

  variables {
    allow_invites_from = "somebodyInvalid"
  }

  expect_failures = [
    var.allow_invites_from,
  ]
}

run "invalid_guest_user_role" {
  command = plan

  variables {
    guest_user_role = "superAdmin"
  }

  expect_failures = [
    var.guest_user_role,
  ]
}
