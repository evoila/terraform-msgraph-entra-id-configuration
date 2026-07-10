variables {
  organization_configuration = {
    notification_email            = "jane.doe@contoso.com"
    language                      = "en"
    default_usage_location        = "AT"
    marketing_notification_emails = ["marketing@contoso.com"]
    privacy_contact_email         = "privacy@contoso.com"
    privacy_statement_url         = "https://contoso.com/privacy"
  }
}

mock_provider "msgraph" {
  mock_resource "msgraph_update_resource" {
    defaults = {
      url = "organization/11111111-2222-3333-4444-555555555555"
    }
  }
}

run "test_preferred_language" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organization_update.body.preferredLanguage == var.organization_configuration.language
    error_message = "Preferred language should be '${var.organization_configuration.language}'"
  }
}

run "test_default_usage_location" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organization_update.body.defaultUsageLocation == var.organization_configuration.default_usage_location
    error_message = "Default usage location should be '${var.organization_configuration.default_usage_location}'"
  }
}

run "test_security_compliance_notification_mails" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organization_update.body.securityComplianceNotificationMails[0] == var.organization_configuration.notification_email
    error_message = "Security compliance notification email should be `${var.organization_configuration.notification_email}`"
  }
}

run "test_technical_notification_mails" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organization_update.body.technicalNotificationMails[0] == var.organization_configuration.notification_email
    error_message = "Technical notification email should be `${var.organization_configuration.notification_email}`"
  }
}

run "test_privacy_profile_contact_email" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organization_update.body.privacyProfile.contactEmail == var.organization_configuration.privacy_contact_email
    error_message = "Privacy profile contact email should be `${var.organization_configuration.privacy_contact_email}`"
  }
}

run "test_privacy_profile_statement_url" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organization_update.body.privacyProfile.statementUrl == var.organization_configuration.privacy_statement_url
    error_message = "Privacy profile statement URL should be `${var.organization_configuration.privacy_statement_url}`"
  }
}

run "test_marketing_notification_emails" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organization_update.body.marketingNotificationEmails[0] == var.organization_configuration.marketing_notification_emails[0]
    error_message = "Marketing notification emails should match the configured list"
  }
}
