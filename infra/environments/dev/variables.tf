variable "location" {
  type = string
  default = "eastus"
}
variable "resource_group_name" {
  type = string
  default = "rg-cloudcart-dev"
}
variable "acr_name" {
  type = string
  description = "Existing shared ACR name, globally unique."
}
variable "vnet_name" {
  type = string
  default = "vnet-cloudcart-dev"
}
variable "aks_name" {
  type = string
  default = "aks-cloudcart-dev"
}
variable "node_count" {
  type = number
  default = 1
}
variable "vm_size" {
  type = string
  default = "Standard_D2s_v5"
}
variable "tags" {
  type = map(string)
  default = { application = "CloudCart", environment = "dev", managed_by = "Terraform" }
}
