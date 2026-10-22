variable "location" {
  type = string
  default = "eastus"
}
variable "resource_group_name" {
  type = string
  default = "rg-cloudcart-prod"
}
variable "acr_name" {
  type = string
  description = "Existing shared ACR name, globally unique."
}
variable "vnet_name" {
  type = string
  default = "vnet-cloudcart-prod"
}
variable "aks_name" {
  type = string
  default = "aks-cloudcart-prod"
}
variable "node_count" {
  type = number
  default = 2
}
variable "vm_size" {
  type = string
  default = "Standard_D2s_v5"
}
variable "tags" {
  type = map(string)
  default = { application = "CloudCart", environment = "prod", managed_by = "Terraform" }
}
