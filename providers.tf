terraform {
  required_version = ">= 1.2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.14.0"
    }
    azapi = {
      source = "Azure/azapi"
      version = ">=2.0.0"
    }
    polaris = {
      source  = "rubrikinc/polaris"
      version = "=0.8.0-beta.4"
    }
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  subscription_id = var.azure_subscription_id
}

provider "azapi" {}

provider "polaris" {}
