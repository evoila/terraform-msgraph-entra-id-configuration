variables {
  organizational_branding_configuration = {
    background_color                       = "#00000F"
    header_background_color                = "#0F0000"
    sign_in_page_text                      = "Contact IT support at support@contoso.com"
    username_hint_text                     = "Use your work email"
    custom_account_reset_credentials_url   = "https://contoso.com/reset"
    custom_cannot_access_your_account_text = "Need help signing in?"
    custom_forgot_my_password_text         = "Forgot password?"
    custom_privacy_and_cookies_text        = "Contoso Privacy"
    custom_privacy_and_cookies_url         = "https://contoso.com/privacy"
    custom_terms_of_use_text               = "Contoso Terms"
    custom_terms_of_use_url                = "https://contoso.com/terms"
    login_page_layout_configuration = {
      layout_template_type = "verticalSplit"
      is_header_shown      = true
      is_footer_shown      = true
    }
    login_page_text_visibility_settings = {
      hide_account_reset_credentials  = false
      hide_cannot_access_your_account = false
      hide_forgot_my_password         = false
      hide_privacy_and_cookies        = false
      hide_reset_it_now               = true
      hide_terms_of_use               = false
    }
  }
}

mock_provider "msgraph" {
  mock_resource "msgraph_update_resource" {
    defaults = {
      url = "organization/11111111-2222-3333-4444-555555555555/branding"
    }
  }
}

run "test_background_color" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organizational_branding_update.body.backgroundColor == var.organizational_branding_configuration.background_color
    error_message = "Background color should be '${var.organizational_branding_configuration.background_color}'"
  }
}

run "test_header_background_color" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organizational_branding_update.body.headerBackgroundColor == var.organizational_branding_configuration.header_background_color
    error_message = "Header background color should be '${var.organizational_branding_configuration.header_background_color}'"
  }
}

run "test_sign_in_page_text" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organizational_branding_update.body.signInPageText == var.organizational_branding_configuration.sign_in_page_text
    error_message = "Sign-in page text should be '${var.organizational_branding_configuration.sign_in_page_text}'"
  }
}

run "test_username_hint_text" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organizational_branding_update.body.usernameHintText == var.organizational_branding_configuration.username_hint_text
    error_message = "Username hint text should be '${var.organizational_branding_configuration.username_hint_text}'"
  }
}

run "test_custom_account_reset_credentials_url" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organizational_branding_update.body.customAccountResetCredentialsUrl == var.organizational_branding_configuration.custom_account_reset_credentials_url
    error_message = "Custom account reset credentials URL should be '${var.organizational_branding_configuration.custom_account_reset_credentials_url}'"
  }
}

run "test_custom_cannot_access_your_account_text" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organizational_branding_update.body.customCannotAccessYourAccountText == var.organizational_branding_configuration.custom_cannot_access_your_account_text
    error_message = "Custom cannot-access-your-account text should be '${var.organizational_branding_configuration.custom_cannot_access_your_account_text}'"
  }
}

run "test_custom_forgot_my_password_text" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organizational_branding_update.body.customForgotMyPasswordText == var.organizational_branding_configuration.custom_forgot_my_password_text
    error_message = "Custom forgot-my-password text should be '${var.organizational_branding_configuration.custom_forgot_my_password_text}'"
  }
}

run "test_custom_privacy_and_cookies_text" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organizational_branding_update.body.customPrivacyAndCookiesText == var.organizational_branding_configuration.custom_privacy_and_cookies_text
    error_message = "Custom privacy-and-cookies text should be '${var.organizational_branding_configuration.custom_privacy_and_cookies_text}'"
  }
}

run "test_custom_privacy_and_cookies_url" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organizational_branding_update.body.customPrivacyAndCookiesUrl == var.organizational_branding_configuration.custom_privacy_and_cookies_url
    error_message = "Custom privacy-and-cookies URL should be '${var.organizational_branding_configuration.custom_privacy_and_cookies_url}'"
  }
}

run "test_custom_terms_of_use_text" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organizational_branding_update.body.customTermsOfUseText == var.organizational_branding_configuration.custom_terms_of_use_text
    error_message = "Custom terms-of-use text should be '${var.organizational_branding_configuration.custom_terms_of_use_text}'"
  }
}

run "test_custom_terms_of_use_url" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organizational_branding_update.body.customTermsOfUseUrl == var.organizational_branding_configuration.custom_terms_of_use_url
    error_message = "Custom terms-of-use URL should be '${var.organizational_branding_configuration.custom_terms_of_use_url}'"
  }
}

run "test_login_page_layout_configuration" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organizational_branding_update.body.loginPageLayoutConfiguration.layoutTemplateType == var.organizational_branding_configuration.login_page_layout_configuration.layout_template_type
    error_message = "Login page layout template type should be '${var.organizational_branding_configuration.login_page_layout_configuration.layout_template_type}'"
  }

  assert {
    condition     = msgraph_update_resource.entra_organizational_branding_update.body.loginPageLayoutConfiguration.isHeaderShown == var.organizational_branding_configuration.login_page_layout_configuration.is_header_shown
    error_message = "Login page 'is header shown' should be '${var.organizational_branding_configuration.login_page_layout_configuration.is_header_shown}'"
  }

  assert {
    condition     = msgraph_update_resource.entra_organizational_branding_update.body.loginPageLayoutConfiguration.isFooterShown == var.organizational_branding_configuration.login_page_layout_configuration.is_footer_shown
    error_message = "Login page 'is footer shown' should be '${var.organizational_branding_configuration.login_page_layout_configuration.is_footer_shown}'"
  }
}

run "test_login_page_text_visibility_settings" {
  command = apply

  assert {
    condition     = msgraph_update_resource.entra_organizational_branding_update.body.loginPageTextVisibilitySettings.hideAccountResetCredentials == var.organizational_branding_configuration.login_page_text_visibility_settings.hide_account_reset_credentials
    error_message = "hideAccountResetCredentials should be '${var.organizational_branding_configuration.login_page_text_visibility_settings.hide_account_reset_credentials}'"
  }

  assert {
    condition     = msgraph_update_resource.entra_organizational_branding_update.body.loginPageTextVisibilitySettings.hideCannotAccessYourAccount == var.organizational_branding_configuration.login_page_text_visibility_settings.hide_cannot_access_your_account
    error_message = "hideCannotAccessYourAccount should be '${var.organizational_branding_configuration.login_page_text_visibility_settings.hide_cannot_access_your_account}'"
  }

  assert {
    condition     = msgraph_update_resource.entra_organizational_branding_update.body.loginPageTextVisibilitySettings.hideForgotMyPassword == var.organizational_branding_configuration.login_page_text_visibility_settings.hide_forgot_my_password
    error_message = "hideForgotMyPassword should be '${var.organizational_branding_configuration.login_page_text_visibility_settings.hide_forgot_my_password}'"
  }

  assert {
    condition     = msgraph_update_resource.entra_organizational_branding_update.body.loginPageTextVisibilitySettings.hidePrivacyAndCookies == var.organizational_branding_configuration.login_page_text_visibility_settings.hide_privacy_and_cookies
    error_message = "hidePrivacyAndCookies should be '${var.organizational_branding_configuration.login_page_text_visibility_settings.hide_privacy_and_cookies}'"
  }

  assert {
    condition     = msgraph_update_resource.entra_organizational_branding_update.body.loginPageTextVisibilitySettings.hideResetItNow == var.organizational_branding_configuration.login_page_text_visibility_settings.hide_reset_it_now
    error_message = "hideResetItNow should be '${var.organizational_branding_configuration.login_page_text_visibility_settings.hide_reset_it_now}'"
  }

  assert {
    condition     = msgraph_update_resource.entra_organizational_branding_update.body.loginPageTextVisibilitySettings.hideTermsOfUse == var.organizational_branding_configuration.login_page_text_visibility_settings.hide_terms_of_use
    error_message = "hideTermsOfUse should be '${var.organizational_branding_configuration.login_page_text_visibility_settings.hide_terms_of_use}'"
  }
}
