output "resource_group_name" { value = azurerm_resource_group.this.name }
output "aks_name" { value = module.aks.name }
output "acr_login_server" { value = data.azurerm_container_registry.shared.login_server }
