resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.firewall_subnet_cidr]
}

resource "azurerm_public_ip" "firewall_pip" {
  name                = "${var.prefix}-afw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags # Теги тут залишаються

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_firewall" "firewall" {
  name                = "${var.prefix}-afw"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  tags                = var.tags # Теги тут залишаються

  ip_configuration {
    name                 = "firewallConfiguration"
    subnet_id            = azurerm_subnet.firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.firewall_pip.id
  }
}

resource "azurerm_route_table" "route_table" {
  name                          = "${var.prefix}-rt"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  bgp_route_propagation_enabled = true     # ВИПРАВЛЕНО
  tags                          = var.tags # Теги тут залишаються

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
  name                = "${var.prefix}-apprc"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = var.resource_group_name
  priority            = 200
  action              = "Allow"
  # tags                = var.tags # ВИДАЛЕНО

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
  name                = "${var.prefix}-netrc"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = var.resource_group_name
  priority            = 100
  action              = "Allow"
  # tags                = var.tags # ВИДАЛЕНО

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
  name                = "${var.prefix}-natrc"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = var.resource_group_name
  priority            = 100 # Змінив пріоритет для NAT правил, зазвичай вони перші
  action              = "Dnat"
  # tags                = var.tags # ВИДАЛЕНО

  dynamic "rule" {
    for_each = var.nat_rule_definitions
    content {
      name                  = rule.value.name
      description           = rule.value.description
      source_addresses      = rule.value.source_addresses
      destination_ports     = rule.value.destination_ports
      destination_addresses = [azurerm_public_ip.firewall_pip.ip_address]
      translated_port       = rule.value.translated_port
      translated_address    = rule.value.translated_address
      protocols             = rule.value.protocols
    }
  }
}