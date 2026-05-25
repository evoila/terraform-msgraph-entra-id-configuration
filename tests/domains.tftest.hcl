variables {
  domains = {
    unit_test_default = {
      name       = "unit-test.invalid"
      is_default = true
    }
  }
}

mock_provider "msgraph" {
  mock_resource "msgraph_resource" {
    defaults = {
      url = "domains"
      body = {
        id                               = "unit-test.invalid"
        isDefault                        = true
        passwordNotificationWindowInDays = 14
        passwordValidityPeriodInDays     = 90
        supportedServices                = []
      }
    }
  }
}

# Test case: Configure custom domains
run "test_domains" {
  command = apply

  assert {
    condition     = msgraph_resource.domains["unit_test_default"].body.id == var.domains.unit_test_default.name
    error_message = "The domain '${var.domains.unit_test_default.name}' should exist."
  }
}
