locals {
  name = "${var.workload}-${var.environment}"
  tags = merge(var.tags, {
    workload    = var.workload
    environment = var.environment
    managed_by  = "terraform"
  })
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name}"
  location = var.location
  tags     = local.tags
}

module "observability" {
  source              = "./modules/observability"
  name                = local.name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  retention_days      = var.environment == "prod" ? 90 : 30
  tags                = local.tags
}

module "registry" {
  source              = "./modules/registry"
  name                = replace(local.name, "-", "")
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  # Premium is required for Private Link + geo-replication; Basic is fine for a demo.
  sku  = var.environment == "prod" ? "Premium" : "Basic"
  tags = local.tags
}

module "keyvault" {
  source              = "./modules/keyvault"
  name                = "kv-${local.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  log_analytics_id    = module.observability.log_analytics_id
  tags                = local.tags
}

# One user-assigned identity: pulls from ACR and reads Key Vault. No credentials in config.
resource "azurerm_user_assigned_identity" "app" {
  name                = "id-${local.name}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = module.registry.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = module.keyvault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

module "app" {
  source                     = "./modules/app"
  name                       = local.name
  resource_group_name        = azurerm_resource_group.this.name
  location                   = azurerm_resource_group.this.location
  log_analytics_id           = module.observability.log_analytics_id
  identity_id                = azurerm_user_assigned_identity.app.id
  registry_login_server      = module.registry.login_server
  image                      = "${module.registry.login_server}/${var.workload}:${var.image_tag}"
  app_version                = var.image_tag
  environment_name           = var.environment
  min_replicas               = var.min_replicas
  max_replicas               = var.max_replicas
  tags                       = local.tags

  # Role assignment must exist before the first image pull, or the revision fails to start.
  depends_on = [azurerm_role_assignment.acr_pull]
}
