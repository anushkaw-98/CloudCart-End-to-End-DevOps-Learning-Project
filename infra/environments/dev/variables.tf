
variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type    = string
  default = "rg-cloudcart-dev"
}

variable "name_prefix" {
  type    = string
  default = "cloudcart-dev"
}

variable "acr_name" {
  description = "Globally unique ACR name: letters and numbers only"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.acr_name))
    error_message = "ACR names must be 5-50 alphanumeric characters."
  }
}

variable "key_vault_name" {
  description = "Globally unique Key Vault name, 3-24 characters"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.key_vault_name))
    error_message = "Use 3-24 letters, numbers, or hyphens."
  }
}

variable "aks_node_count" {
  type    = number
  default = 1
}

variable "aks_node_vm_size" {
  type    = string
  default = "Standard_D2s_v5"
}
