# Configure Access Review definitions
# see https://learn.microsoft.com/en-us/graph/api/resources/accessreviewsv2-overview

resource "msgraph_resource" "access_review_definition" {
  for_each = local.tenant_has_p2_license ? var.access_reviews : {} # Access reviews required Entra ID P2 license

  url           = "identityGovernance/accessReviews/definitions"
  update_method = "PUT"

  body = {
    displayName             = each.value.display_name
    descriptionForReviewers = each.value.description_for_reviewers
    descriptionForAdmins    = coalesce(each.value.description_for_admins, each.value.description_for_reviewers)

    scope = each.value.scope.template != null ? jsondecode(templatefile(
      "${path.module}/templates/access_review_scopes/${each.value.scope.template}.tftpl.json",
      each.value.scope.template_vars
      )) : {
      "@odata.type" = "#microsoft.graph.accessReviewQueryScope"
      query         = each.value.scope.query
      queryType     = each.value.scope.query_type
      queryRoot     = each.value.scope.query_root
    }
    instanceEnumerationScope = each.value.instance_enumeration_scope == null ? null : (
      each.value.instance_enumeration_scope.template != null ? jsondecode(templatefile(
        "${path.module}/templates/access_review_instance_enumeration_scopes/${each.value.instance_enumeration_scope.template}.tftpl.json",
        each.value.instance_enumeration_scope.template_vars
        )) : {
        "@odata.type" = "#microsoft.graph.accessReviewQueryScope"
        query         = each.value.instance_enumeration_scope.query
        queryType     = each.value.instance_enumeration_scope.query_type
        queryRoot     = each.value.instance_enumeration_scope.query_root
      }
    )

    settings = {
      mailNotificationsEnabled        = each.value.settings.mail_notifications_enabled
      reminderNotificationsEnabled    = each.value.settings.reminder_notifications_enabled
      justificationRequiredOnApproval = each.value.settings.justification_required_on_approval
      instanceDurationInDays          = each.value.settings.instance_duration_in_days
      autoApplyDecisionsEnabled       = each.value.settings.auto_apply_decisions_enabled
      recurrence = {
        pattern = each.value.settings.recurrence.pattern == null ? null : {
          type           = each.value.settings.recurrence.pattern.type
          interval       = each.value.settings.recurrence.pattern.interval
          month          = each.value.settings.recurrence.pattern.month
          dayOfMonth     = each.value.settings.recurrence.pattern.day_of_month
          daysOfWeek     = each.value.settings.recurrence.pattern.days_of_week
          firstDayOfWeek = each.value.settings.recurrence.pattern.first_day_of_week
          index          = each.value.settings.recurrence.pattern.index
        }
        range = {
          startDate           = each.value.settings.recurrence.range.start_date
          endDate             = each.value.settings.recurrence.range.end_date
          type                = each.value.settings.recurrence.range.type
          numberOfOccurrences = each.value.settings.recurrence.range.number_of_occurrences
          recurrenceTimeZone  = each.value.settings.recurrence.range.recurrence_time_zone
        }
      }

      defaultDecisionEnabled               = each.value.settings.default_decision_enabled
      defaultDecision                      = each.value.settings.default_decision
      decisionHistoriesForReviewersEnabled = each.value.settings.decision_histories_for_reviewers_enabled

      recommendationsEnabled         = each.value.settings.recommendations_enabled
      recommendationLookBackDuration = each.value.settings.recommendation_look_back_duration

      applyActions = each.value.settings.apply_actions == null ? [] : [{
        "@odata.type" = each.value.settings.apply_actions == "removeAccessApplyAction" ? "#microsoft.graph.removeAccessApplyAction" : "#microsoft.graph.disableAndDeleteUserApplyAction"
      }]
    }

    reviewers = [for reviewer in each.value.reviewers : {
      query     = reviewer.query
      queryType = reviewer.query_type
      queryRoot = reviewer.query_root
    }]
    fallbackReviewers = [for reviewer in each.value.fallback_reviewers : {
      query     = reviewer.query
      queryType = reviewer.query_type
      queryRoot = reviewer.query_root
    }]
    additionalNotificationRecipients = [for recipient in each.value.additional_notification_recipients : {
      "@odata.type"            = "#microsoft.graph.accessReviewNotificationRecipientItem"
      notificationTemplateType = recipient.notification_template_type
      notificationRecipientScope = {
        "@odata.type" = "#microsoft.graph.accessReviewNotificationRecipientQueryScope"
        query         = recipient.notification_recipient_scope.query
        queryType     = "MicrosoftGraph"
        queryRoot     = recipient.notification_recipient_scope.query_root
      }
    }]

    #stageSettings = null # not implemented yet
  }
}
