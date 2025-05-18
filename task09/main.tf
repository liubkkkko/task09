provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "aks_subnet" {
  name                 = var.aks_subnet_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

module "afw" {
  source = "./modules/afw"

  prefix               = local.prefix
  location             = var.location
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  firewall_subnet_cidr = var.firewall_subnet_cidr
  aks_subnet_id        = data.azurerm_subnet.aks_subnet.id
  aks_subnet_cidr      = data.azurerm_subnet.aks_subnet.address_prefixes[0]
  aks_loadbalancer_ip  = var.aks_loadbalancer_ip
  tags                 = local.common_tags

  # Pass rule definitions from locals
  application_rule_definitions = local.application_rule_definitions
  network_rule_definitions     = local.network_rule_definitions
  nat_rule_definitions         = local.nat_rule_definitions
}