
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region for Terraform state"
  type        = string
  default     = "eastus"
}

variable "state_resource_group_name" {
  type    = string
  default = "rg-cloudcart-tfstate"
}

variable "state_storage_account_name" {
  description = "Globally unique lowercase name, 3-24 characters"
  type        = string

  validation {
    condition = (
      length(var.state_storage_account_name) >= 3 &&
      length(var.state_storage_account_name) <= 24 &&
      can(regex("^[a-z0-9]+$", var.state_storage_account_name))
    )
    error_message = "Use 3-24 lowercase letters and numbers only."
  }
}

variable "state_container_name" {
  type    = string
  default = "tfstate"
}
