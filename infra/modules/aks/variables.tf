variable "aks_name" {
  type = string
}
variable "location" {
  type = string
}
variable "resource_group_name" {
  type = string
}
variable "dns_prefix" {
  type = string
}
variable "sku_tier" {
  type = string
  default = "Free"
}
variable "node_count" {
  type = number
  default = 1
}
variable "vm_size" {
  type = string
  default = "Standard_D2s_v5"
}
variable "aks_subnet_id" {
  type = string
}
variable "service_cidr" {
  type = string
}
variable "dns_service_ip" {
  type = string
}
variable "acr_id" {
  type = string
}
variable "tags" {
  type = map(string)
}
