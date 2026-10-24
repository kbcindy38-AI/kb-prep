output "resource_group" {
  value = azurerm_resource_group.this.name
}

output "app_name" {
  value = module.app.name
}

output "app_url" {
  value = module.app.url
}

output "registry_login_server" {
  value = module.registry.login_server
}
