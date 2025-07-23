terraform {
  required_version = ">= 1.2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.14.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">=2.0.0"
    }
    polaris = {
      source  = "rubrikinc/polaris"
      version = "=>1.1.3"
    }
  }
}
