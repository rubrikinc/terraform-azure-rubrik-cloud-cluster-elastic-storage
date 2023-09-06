terraform {
  required_version = ">= 1.2.0"
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    azapi = {
      source = "Azure/azapi"
    }
    rubrik = {
      source   = "rubrikinc/rubrik/rubrik"
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
}

provider "azapi" {}

provider "rubrik" {
  node_ip  = local.cluster_node_ips.0
  username = ""
  password = ""
}