terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Remote state with Entra ID auth (no storage keys). Values are passed at init time:
  #   terraform init -backend-config=envs/dev.backend.hcl
  # Locally / in the interview: `terraform init -backend=false` is enough to validate.
  backend "azurerm" {
    use_oidc         = true
    use_azuread_auth = true
  }
}
