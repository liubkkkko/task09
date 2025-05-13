data "azurerm_resource_group" "existing_rg" {
  name = var.existing_resource_group_name
}

data "azurerm_virtual_network" "existing_vnet" {
  name                = var.existing_vnet_name
  resource_group_name = data.azurerm_resource_group.existing_rg.name
}

data "azurerm_subnet" "existing_aks_snet" {
  name                 = var.existing_aks_subnet_name
  virtual_network_name = data.azurerm_virtual_network.existing_vnet.name
  resource_group_name  = data.azurerm_resource_group.existing_rg.name
}

module "azure_firewall" {
  source = "./modules/afw"

  prefix                         = var.prefix
  location                       = var.location
  resource_group_name            = data.azurerm_resource_group.existing_rg.name
  virtual_network_name           = data.azurerm_virtual_network.existing_vnet.name
  aks_subnet_id                  = data.azurerm_subnet.existing_aks_snet.id
  aks_subnet_address_prefixes    = data.azurerm_subnet.existing_aks_snet.address_prefixes
  aks_loadbalancer_ip            = var.aks_loadbalancer_ip
  firewall_subnet_address_prefix = var.firewall_subnet_address_prefix
  tags                           = var.tags
}