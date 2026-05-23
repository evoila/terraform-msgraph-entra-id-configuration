variables {
  tenant_language = "es"
}

mock_provider "msgraph" {
  mock_resource "msgraph_update_resource" {
    defaults = {
      url = "organization/11111111-2222-3333-4444-555555555555"
      body = {
        preferredLanguage                   = "es"
        securityComplianceNotificationMails = ["jane.doe@contoso.com"]
        technicalNotificationMails          = ["jane.doe@contoso.com"]
      }
    }
  }
}

run "test_preferred_language" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organization_update.body.preferredLanguage == var.tenant_language
    error_message = "Preferred language should be '${var.tenant_language}'"
  }
}

run "test_security_compliance_notification_mails" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organization_update.body.securityComplianceNotificationMails[0] == var.tenant_notification_email
    error_message = "Security compliance notification email should be `${var.tenant_notification_email}`"
  }
}

run "test_technical_notification_mails" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organization_update.body.technicalNotificationMails[0] == var.tenant_notification_email
    error_message = "Technical notification email should be `${var.tenant_notification_email}`"
  }
}
