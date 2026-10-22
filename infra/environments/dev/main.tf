resource "azurerm_resource_group" "this" {
  name = var.resource_group_name
  location = var.location
  tags = var.tags
}

data "azurerm_container_registry" "shared" {
  name = var.acr_name
  resource_group_name = "rg-cloudcart-dev"
}

module "network" {
  source = "../../modules/network"
  resource_group_name = azurerm_resource_group.this.name
  location = azurerm_resource_group.this.location
  vnet_name = var.vnet_name
  address_space = ["10.20.0.0/16"]
  aks_subnet_name = "snet-aks-dev"
  aks_subnet_prefixes = ["10.20.0.0/20"]
  private_endpoints_subnet_name = "snet-private-endpoints-dev"
  private_endpoints_subnet_prefixes = ["10.20.16.0/24"]
  tags = var.tags
}

module "aks" {
  source = "../../modules/aks"
  aks_name = var.aks_name
  location = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix = "cloudcart-dev"
  sku_tier = "Free"
  node_count = var.node_count
  vm_size = var.vm_size
  aks_subnet_id = module.network.aks_subnet_id
  service_cidr = "10.21.0.0/16"
  dns_service_ip = "10.21.0.10"
  acr_id = data.azurerm_container_registry.shared.id
  tags = var.tags
}
