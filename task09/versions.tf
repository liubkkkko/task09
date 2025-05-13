terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Using a common recent version range
    }
  }
}

provider "azurerm" {
  features {}
}