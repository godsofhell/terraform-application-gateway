terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.9.0"
    }
  }
}

provider "azurerm" {
  features {}
  client_id = "4100c47e-4d39-4cd6-9af9-8ce7c5e5142d"
  client_secret = "G0J8Q~EX9URj2~AKeNImRjh-arz7muTTvigBCduh"
  tenant_id = "8cddfc2a-1f62-42be-a522-8ae3ca2fc894"
  subscription_id = "2ab4f266-3113-46c7-9a11-16bcb8ae5659"
}