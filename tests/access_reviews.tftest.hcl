variables {
  access_reviews = {
    test = {
      display_name              = "Test Review"
      description_for_reviewers = "Unit test for access review definition"
      description_for_admins    = "Unit test description"
      scope = {
        query = "/v1.0/groups/11111111-2222-3333-4444-555555555555/transitiveMembers/microsoft.graph.user"
      }
      instance_enumeration_scope = {
        query = "/v1.0/groups/11111111-2222-3333-4444-555555555555"
      }
      settings = {
        mail_notifications_enabled         = true
        reminder_notifications_enabled     = true
        justification_required_on_approval = true
        instance_duration_in_days          = 5
        auto_apply_decisions_enabled       = true
        apply_actions                      = "disableAndDeleteUserApplyAction"
        recurrence = {
          pattern = null
          range = {
            start_date = "2026-01-01"
            end_date   = "2026-12-31"
            type       = "numbered"
          }
        }
        default_decision                         = "Deny"
        default_decision_enabled                 = true
        decision_histories_for_reviewers_enabled = false
        recommendations_enabled                  = false
        recommendation_look_back_duration        = 0
      }
      reviewers = [{
        query = "/v1.0/groups/11111111-2222-3333-4444-555555555555/transitiveMembers/microsoft.graph.user"
      }]
      fallback_reviewers = [{
        query = "/v1.0/groups/22222222-3333-4444-5555-666666666666/transitiveMembers/microsoft.graph.user"
      }]
      additional_notification_recipients = [{
        "@odata.type"              = "#microsoft.graph.accessReviewNotificationRecipientItem"
        notification_template_type = "Email"
        notification_recipient_scope = {
          "@odata.type" = "#microsoft.graph.accessReviewNotificationRecipientQueryScope"
          query         = "/v1.0/groups/99999999-0000-0000-0000-000000000000/transitiveMembers/microsoft.graph.user"
        }
      }]
    }
  }
}

mock_provider "msgraph" {
  # Access Reviews are an Entra ID P2 feature, so we must inject the service
  # plan (license) into the data source to enable testing
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
  mock_resource "msgraph_resource" {

    defaults = {
      url           = "identityGovernance/accessReviews/definitions"
      update_method = "PUT"
      body = {
        displayName             = "Comprehensive Test Review"
        descriptionForReviewers = "Comprehensive unit test for access review definition"
        descriptionForAdmins    = "Comprehensive unit test for access review definition"
        scope = {
          "@odata.type" = "#microsoft.graph.accessReviewQueryScope"
          query         = "/v1.0/groups/11111111-2222-3333-4444-555555555555/transitiveMembers/microsoft.graph.user"
          queryType     = "MicrosoftGraph"
        }
        instanceEnumerationScope = {
          "@odata.type" = "#microsoft.graph.accessReviewQueryScope"
          query         = "/v1.0/groups/11111111-2222-3333-4444-555555555555"
          queryType     = "MicrosoftGraph"
        }
        settings = {
          instanceDurationInDays = 5
          recurrence = {
            pattern = null
            range = {
              startDate = "2026-01-01"
              endDate   = "2026-12-31"
              type      = "numbered"
            }
          }
          mailNotificationsEnabled             = true
          reminderNotificationsEnabled         = true
          justificationRequiredOnApproval      = true
          autoApplyDecisionsEnabled            = true
          defaultDecisionEnabled               = true
          defaultDecision                      = "Deny"
          decisionHistoriesForReviewersEnabled = false
          recommendationsEnabled               = false
          recommendationLookBackDuration       = 0
          applyActions = [{
            "@odata.type" = "#microsoft.graph.disableAndDeleteUserApplyAction"
          }]
        }
      }
    }
  }
}

# Test case 1: Basic attributes and Scope
run "test_basic_attributes" {
  command = apply
  assert {
    condition     = msgraph_resource.access_review_definition["test"].body.displayName == var.access_reviews.test.display_name
    error_message = "DisplayName should match the comprehensive test data."
  }
  assert {
    condition     = msgraph_resource.access_review_definition["test"].body.descriptionForAdmins == var.access_reviews.test.description_for_admins
    error_message = "Admin Description should match the comprehensive test data."
  }
  assert {
    condition     = msgraph_resource.access_review_definition["test"].body.scope.query == var.access_reviews.test.scope.query
    error_message = "Scope query should match the comprehensive test data."
  }
}

# Test case 2: Instance Enumeration Scope
run "test_enumeration_scope" {
  command = apply
  assert {
    condition     = msgraph_resource.access_review_definition["test"].body.instanceEnumerationScope.query == var.access_reviews.test.instance_enumeration_scope.query
    error_message = "Instance Enumeration Scope query should match."
  }
  assert {
    condition     = msgraph_resource.access_review_definition["test"].body.instanceEnumerationScope.queryType == var.access_reviews.test.instance_enumeration_scope.query_type
    error_message = "Instance Enumeration Scope queryType should match."
  }
}

# Test case 3: Settings and Duration
run "test_settings" {
  command = apply
  assert {
    condition     = msgraph_resource.access_review_definition["test"].body.settings.instanceDurationInDays == var.access_reviews.test.settings.instance_duration_in_days
    error_message = "InstanceDurationInDays should match."
  }
  assert {
    condition     = msgraph_resource.access_review_definition["test"].body.settings.mailNotificationsEnabled == var.access_reviews.test.settings.mail_notifications_enabled
    error_message = "MailNotificationsEnabled should match."
  }
  assert {
    condition     = msgraph_resource.access_review_definition["test"].body.settings.justificationRequiredOnApproval == var.access_reviews.test.settings.justification_required_on_approval
    error_message = "JustificationRequiredOnApproval should match."
  }
}

# Test case 4: Recurrence settings
run "test_recurrence" {
  command = apply
  assert {
    condition     = msgraph_resource.access_review_definition["test"].body.settings.recurrence.pattern == var.access_reviews.test.settings.recurrence.pattern
    error_message = "Recurrence pattern should match."
  }
  assert {
    condition     = msgraph_resource.access_review_definition["test"].body.settings.recurrence.range.endDate == var.access_reviews.test.settings.recurrence.range.end_date
    error_message = "Recurrence range end date should match."
  }
}

# Test case 5: Default Decision and Apply Actions
run "test_decisions_and_actions" {
  command = apply
  assert {
    condition     = msgraph_resource.access_review_definition["test"].body.settings.defaultDecision == var.access_reviews.test.settings.default_decision
    error_message = "Default decision should match."
  }
  assert {
    condition     = strcontains(msgraph_resource.access_review_definition["test"].body.settings.applyActions[0]["@odata.type"], var.access_reviews.test.settings.apply_actions)
    error_message = "Apply Action type should match."
  }
}

# Test case 6: Reviewers and Fallback Reviewers
run "test_reviewers" {
  command = apply
  assert {
    condition     = length(msgraph_resource.access_review_definition["test"].body.reviewers) == length(var.access_reviews.test.reviewers)
    error_message = "Number of reviewers should match."
  }
  assert {
    condition     = msgraph_resource.access_review_definition["test"].body.reviewers[0].query == var.access_reviews.test.reviewers[0].query
    error_message = "Reviewer 0 query should match."
  }
}

# Test case 7: Notification Recipients
run "test_notification_recipients" {
  command = apply
  assert {
    condition     = length(msgraph_resource.access_review_definition["test"].body.additionalNotificationRecipients) == length(var.access_reviews.test.additional_notification_recipients)
    error_message = "Number of notification recipients should match."
  }
  assert {
    condition     = msgraph_resource.access_review_definition["test"].body.additionalNotificationRecipients[0].notificationRecipientScope.query == var.access_reviews.test.additional_notification_recipients[0].notification_recipient_scope.query
    error_message = "Notification recipient scope query should match."
  }
}

# Test case 8: Template-based scope (decoded JSON, polymorphic body)
run "test_scope_template" {
  command = apply

  variables {
    access_reviews = {
      test = {
        display_name              = "Test Review"
        description_for_reviewers = "Unit test for access review definition"
        scope = {
          template      = "users_assigned_to_group"
          template_vars = { group_id = "11111111-2222-3333-4444-555555555555" }
        }
        settings = {
          recurrence = {
            pattern = null
            range = {
              start_date = "2026-01-01"
            }
          }
        }
      }
    }
  }

  assert {
    condition     = msgraph_resource.access_review_definition["test"].body.scope["@odata.type"] == "#microsoft.graph.accessReviewQueryScope"
    error_message = "Template-based scope should decode the @odata.type discriminator from the template file."
  }
  assert {
    condition     = strcontains(msgraph_resource.access_review_definition["test"].body.scope.query, "11111111-2222-3333-4444-555555555555")
    error_message = "Template-based scope query should have group_id interpolated."
  }
}

# Test case 9: Template-based instance_enumeration_scope
run "test_instance_enumeration_scope_template" {
  command = apply

  variables {
    access_reviews = {
      test = {
        display_name              = "Test Review"
        description_for_reviewers = "Unit test for access review definition"
        scope = {
          query = "/v1.0/groups/11111111-2222-3333-4444-555555555555/transitiveMembers/microsoft.graph.user"
        }
        instance_enumeration_scope = {
          template = "any_m365_group"
        }
        settings = {
          recurrence = {
            pattern = null
            range = {
              start_date = "2026-01-01"
            }
          }
        }
      }
    }
  }

  assert {
    condition     = can(msgraph_resource.access_review_definition["test"].body.instanceEnumerationScope.query)
    error_message = "Template-based instance_enumeration_scope should produce a decoded query field."
  }
}

# Test case 10: scope xor validation - both template and query set should fail
run "test_scope_template_and_query_conflict_fails" {
  command = plan

  variables {
    access_reviews = {
      test = {
        display_name              = "Test Review"
        description_for_reviewers = "Unit test for access review definition"
        scope = {
          template = "users_assigned_to_group"
          query    = "/v1.0/groups/11111111-2222-3333-4444-555555555555"
        }
        settings = {
          recurrence = {
            pattern = null
            range   = { start_date = "2026-01-01" }
          }
        }
      }
    }
  }

  expect_failures = [
    var.access_reviews,
  ]
}

# Test case 11: instance_enumeration_scope xor validation - neither template nor query set should fail
run "test_instance_enumeration_scope_neither_template_nor_query_fails" {
  command = plan

  variables {
    access_reviews = {
      test = {
        display_name              = "Test Review"
        description_for_reviewers = "Unit test for access review definition"
        scope = {
          query = "/v1.0/groups/11111111-2222-3333-4444-555555555555"
        }
        instance_enumeration_scope = {
          query_type = "MicrosoftGraph"
        }
        settings = {
          recurrence = {
            pattern = null
            range   = { start_date = "2026-01-01" }
          }
        }
      }
    }
  }

  expect_failures = [
    var.access_reviews,
  ]
}

# Test case 12: template must exist on disk
run "test_scope_template_nonexistent_fails" {
  command = plan

  variables {
    access_reviews = {
      test = {
        display_name              = "Test Review"
        description_for_reviewers = "Unit test for access review definition"
        scope = {
          template = "does_not_exist"
        }
        settings = {
          recurrence = {
            pattern = null
            range   = { start_date = "2026-01-01" }
          }
        }
      }
    }
  }

  expect_failures = [
    var.access_reviews,
  ]
}

# Test case 13: default_decision enum validation failure
run "test_default_decision_invalid_fails" {
  command = plan

  variables {
    access_reviews = {
      test = {
        display_name              = "Test Review"
        description_for_reviewers = "Unit test for access review definition"
        scope = {
          query = "/v1.0/groups/11111111-2222-3333-4444-555555555555"
        }
        settings = {
          default_decision = "Maybe"
          recurrence = {
            pattern = null
            range   = { start_date = "2026-01-01" }
          }
        }
      }
    }
  }

  expect_failures = [
    var.access_reviews,
  ]
}
