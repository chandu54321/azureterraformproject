terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0" # Adjust this to the latest version as needed
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "9aaf3eea-4c43-490d-a2d4-d95e9794b900"
}