# Test case: tenant license level is derived from the subscribed SKUs' service plan GUIDs.
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

run "test_license_level_free_by_default" {
  command = plan

  assert {
    condition     = output.license_level == "Free"
    error_message = "License level should be 'Free' when no P1/P2 service plan is present."
  }
}

run "test_license_level_p1" {
  command = plan

  override_data {
    target = data.msgraph_resource.subscribed_skus
    values = {
      output = {
        service_plans = [
          [
            { servicePlanId = "41781fb2-bc02-4b7c-bd55-b576c07bb09d" },
          ],
        ]
      }
    }
  }

  assert {
    condition     = output.license_level == "P1"
    error_message = "License level should be 'P1' when the P1 service plan GUID is present."
  }
}

run "test_license_level_p2" {
  command = plan

  override_data {
    target = data.msgraph_resource.subscribed_skus
    values = {
      output = {
        service_plans = [
          [
            { servicePlanId = "eec0eb4f-6444-4f95-aba0-50c24d67f998" },
          ],
        ]
      }
    }
  }

  assert {
    condition     = output.license_level == "P2"
    error_message = "License level should be 'P2' when the P2 service plan GUID is present."
  }
}

run "test_license_level_p2_takes_precedence_over_p1" {
  command = plan

  override_data {
    target = data.msgraph_resource.subscribed_skus
    values = {
      output = {
        service_plans = [
          [
            { servicePlanId = "41781fb2-bc02-4b7c-bd55-b576c07bb09d" },
            { servicePlanId = "eec0eb4f-6444-4f95-aba0-50c24d67f998" },
          ],
        ]
      }
    }
  }

  assert {
    condition     = output.license_level == "P2"
    error_message = "License level should resolve to 'P2' when both P1 and P2 service plans are present."
  }
}
