resource "azurerm_subnet" "firewall_subnet" {
  # Use the required Azure Firewall subnet name
  name                 = local.firewall_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.firewall_subnet_cidr]
}

resource "azurerm_public_ip" "firewall_pip" {
  # Use the corrected local name
  name                = local.pip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_firewall" "firewall" {
  # Use the local name
  name                = local.firewall_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  tags                = var.tags

  ip_configuration {
    name                 = "firewallConfiguration"
    subnet_id            = azurerm_subnet.firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.firewall_pip.id
  }
}

resource "azurerm_route_table" "route_table" {
  # Use the local name
  name                          = local.rt_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  bgp_route_propagation_enabled = true
  tags                          = var.tags

  route {
    name                   = "DefaultToFirewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "aks_subnet_association" {
  subnet_id      = var.aks_subnet_id
  route_table_id = azurerm_route_table.route_table.id
}

resource "azurerm_firewall_application_rule_collection" "app_rules" {
  name                = "${var.prefix}-apprc" # Naming is acceptable as it's not a top-level resource type in the abbr list
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = var.resource_group_name
  priority            = 200
  action              = "Allow"

  dynamic "rule" {
    for_each = var.application_rule_definitions
    content {
      name             = rule.value.name
      description      = rule.value.description
      source_addresses = rule.value.source_addresses
      target_fqdns     = rule.value.target_fqdns
      dynamic "protocol" {
        for_each = rule.value.protocols
        content {
          port = protocol.value.port
          type = protocol.value.type
        }
      }
    }
  }
}

resource "azurerm_firewall_network_rule_collection" "network_rules" {
  name                = "${var.prefix}-netrc" # Naming is acceptable
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = var.resource_group_name
  priority            = 100
  action              = "Allow"

  dynamic "rule" {
    for_each = var.network_rule_definitions
    content {
      name                  = rule.value.name
      description           = rule.value.description
      source_addresses      = rule.value.source_addresses
      destination_ports     = rule.value.destination_ports
      destination_addresses = rule.value.destination_addresses
      protocols             = rule.value.protocols
    }
  }
}

resource "azurerm_firewall_nat_rule_collection" "nat_rules" {
  name                = "${var.prefix}-natrc" # Naming is acceptable
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = var.resource_group_name
  priority            = 100
  action              = "Dnat"

  dynamic "rule" {
    for_each = var.nat_rule_definitions
    content {
      name              = rule.value.name
      description       = rule.value.description
      source_addresses  = rule.value.source_addresses
      destination_ports = rule.value.destination_ports
      # Destination is the Firewall's public IP
      destination_addresses = [azurerm_public_ip.firewall_pip.ip_address]
      translated_port       = rule.value.translated_port
      # TRANSLATION FIX: Target the first usable IP in the AKS subnet (internal IP)
      translated_address = cidrhost(var.aks_subnet_cidr, 4)
      protocols          = rule.value.protocols
    }
  }
}