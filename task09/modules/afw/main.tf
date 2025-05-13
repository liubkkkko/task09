resource "azurerm_subnet" "firewall_snet" {
  name                 = local.firewall_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.firewall_subnet_address_prefix]
}

resource "azurerm_public_ip" "firewall_pip" {
  name                = local.firewall_pip_name
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard" # Azure Firewall requires Standard SKU PIP
  tags                = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_firewall" "afw" {
  name                = local.firewall_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "AZFW_VNet" # For Standard Firewall associated with a VNet
  sku_tier            = "Standard"
  tags                = var.tags

  ip_configuration {
    name                 = "firewallConfiguration" # Internal name for the IP configuration
    subnet_id            = azurerm_subnet.firewall_snet.id
    public_ip_address_id = azurerm_public_ip.firewall_pip.id
  }
}

resource "azurerm_route_table" "rt" {
  name                          = local.route_table_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  bgp_route_propagation_enabled = true # Default; set to true if you want to rely only on UDRs
  tags                          = var.tags

  route {
    name                   = "DefaultToFirewall"
    address_prefix         = "0.0.0.0/0" # Route all outbound traffic
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.afw.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "aks_snet_rt_assoc" {
  subnet_id      = var.aks_subnet_id
  route_table_id = azurerm_route_table.rt.id
}

resource "azurerm_firewall_application_rule_collection" "app_rule_collection" {
  name                = local.app_rule_collection_name
  azure_firewall_name = azurerm_firewall.afw.name
  resource_group_name = var.resource_group_name
  priority            = 200 # Example priority (100-65000)
  action              = "Allow"

  dynamic "rule" {
    for_each = local.aks_application_rules
    content {
      name             = rule.value.name
      description      = rule.value.description
      source_addresses = rule.value.source_addresses
      target_fqdns     = rule.value.target_fqdns
      dynamic "protocol" {
        for_each = rule.value.protocols
        content {
          type = protocol.value.type
          port = protocol.value.port
        }
      }
    }
  }
}

resource "azurerm_firewall_network_rule_collection" "network_rule_collection" {
  name                = local.network_rule_collection_name
  azure_firewall_name = azurerm_firewall.afw.name
  resource_group_name = var.resource_group_name
  priority            = 100 # Network rules often have higher priority than app rules within their type class
  action              = "Allow"

  dynamic "rule" {
    for_each = local.aks_network_rules
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

resource "azurerm_firewall_nat_rule_collection" "nat_rule_collection" {
  name                = local.nat_rule_collection_name
  azure_firewall_name = azurerm_firewall.afw.name
  resource_group_name = var.resource_group_name
  priority            = 100 # NAT rules are processed first; lower number = higher priority
  action              = "Dnat"

  rule {
    name               = "nginx-ingress-http"
    description        = "DNAT rule for NGINX service on port 80"
    source_addresses   = ["*"] # Or specific IPs if source needs restriction
    destination_ports  = ["80"]
    destination_addresses = [azurerm_public_ip.firewall_pip.ip_address] # Firewall's public IP
    translated_address = var.aks_loadbalancer_ip                         # NGINX service IP
    translated_port    = "80"                                            # NGINX service port
    protocols          = ["TCP"]
  }
  # Add another rule here if NGINX also serves on HTTPS/443 and needs to be exposed.
}