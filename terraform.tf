terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    # Microsoft Graph provider
    # https://registry.terraform.io/providers/microsoft/msgraph/latest
    msgraph = {
      source  = "microsoft/msgraph"
      version = ">= 0.3.0"
    }
  }
}
