provider "azurerm" {
  features {}
}

# Get existing resource group
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Get existing virtual network
data "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Get existing AKS subnet
data "azurerm_subnet" "aks_subnet" {
  name                 = var.aks_subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

  # Create Azure Firewall and related resources using the module
module "afw" {
  source = "./modules/afw"

  prefix              = local.prefix
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  
  firewall_subnet_cidr = var.firewall_subnet_cidr
  aks_subnet_id        = data.azurerm_subnet.aks_subnet.id
  aks_subnet_cidr      = var.aks_subnet_cidr
  aks_loadbalancer_ip  = var.aks_loadbalancer_ip
  additional_app_rules = var.additional_app_rules
  
  tags = local.common_tags
}