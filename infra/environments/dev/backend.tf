terraform {
  backend "azurerm" {
    resource_group_name  = "rg-cloudcart-tfstate"
    storage_account_name = "REPLACE_WITH_EXISTING_TFSTATE_STORAGE_ACCOUNT"
    container_name       = "tfstate"
    key                  = "cloudcart-dev.tfstate"
    use_azuread_auth     = true
  }
}



