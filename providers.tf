provider "azurerm" {
  # "public" = Azure Commercial, "usgovernment" = Azure Government. Same code, different endpoints.
  environment     = var.cloud_environment
  subscription_id = var.subscription_id
  use_oidc        = true # GitHub Actions federated credential: no client secret stored anywhere

  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}
