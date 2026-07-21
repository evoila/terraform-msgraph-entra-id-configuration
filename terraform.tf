terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    # Microsoft Graph provider
    # https://registry.terraform.io/providers/microsoft/msgraph/latest
    msgraph = {
      source  = "microsoft/msgraph"
      version = ">= 0.3.0"
    }
    # Used to auto-generate initial passwords for users without an entry in var.user_passwords
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }
  }
}
