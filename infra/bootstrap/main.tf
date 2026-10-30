
resource "azurerm_resource_group" "state" {
  name     = var.state_resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "state" {
  name                     = var.state_storage_account_name
  resource_group_name      = azurerm_resource_group.state.name
  location                 = azurerm_resource_group.state.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  https_traffic_only_enabled = true
  shared_access_key_enabled  = false

  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "state" {
  name                  = var.state_container_name
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}
