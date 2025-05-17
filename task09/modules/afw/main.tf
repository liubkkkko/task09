resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet" # This is a mandatory name for the Azure Firewall subnet
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

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "azurerm_firewall" "firewall" {
  name                = "${var.prefix}-afw"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.firewall_pip.id
  }

  tags = var.tags
}

resource "azurerm_route_table" "route_table" {
  name                = "${var.prefix}-rt"
  location            = var.location
  resource_group_name = var.resource_group_name

  route {
    name                   = "to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }

  tags = var.tags
}

resource "azurerm_subnet_route_table_association" "aks_subnet_association" {
  subnet_id      = var.aks_subnet_id
  route_table_id = azurerm_route_table.route_table.id
}

resource "azurerm_firewall_application_rule_collection" "app_rules" {
  name                = "${var.prefix}-app-rules"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = var.resource_group_name
  priority            = 100
  action              = "Allow"

  rule {
    name = "allow-aks-required-fqdns"
    source_addresses = [
      var.aks_subnet_cidr
    ]

    target_fqdns = [
      "*.hcp.eastus.azmk8s.io",
      "mcr.microsoft.com",
      "*.data.mcr.microsoft.com",
      "management.azure.com",
      "login.microsoftonline.com",
      "packages.microsoft.com",
      "acs-mirror.azureedge.net",
      "*.docker.io",
      "*.docker.com",
      "*.cloudflare.docker.com",
      "*azurecr.io",
      "*cdn.mscr.io",
      "*.blob.core.windows.net",
      "*.trafficmanager.net",
      "*.azureedge.net"
    ]

    protocol {
      port = "443"
      type = "Https"
    }

    protocol {
      port = "80"
      type = "Http"
    }
  }

  rule {
    name = "allow-additional-fqdns"
    source_addresses = [
      var.aks_subnet_cidr
    ]

    target_fqdns = var.additional_app_rules

    protocol {
      port = "443"
      type = "Https"
    }

    protocol {
      port = "80"
      type = "Http"
    }
  }

  rule {
    name             = "allow-all-web-browsing"
    source_addresses = ["*"]
    target_fqdns     = ["*"]

    protocol {
      port = "80"
      type = "Http"
    }

    protocol {
      port = "443"
      type = "Https"
    }
  }
}

resource "azurerm_firewall_network_rule_collection" "network_rules" {
  name                = "${var.prefix}-network-rules"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = var.resource_group_name
  priority            = 200
  action              = "Allow"

  rule {
    name                  = "allow-dns"
    source_addresses      = [var.aks_subnet_cidr]
    destination_ports     = ["53"]
    destination_addresses = ["*"]
    protocols             = ["UDP", "TCP"]
  }

  rule {
    name                  = "allow-ntp"
    source_addresses      = [var.aks_subnet_cidr]
    destination_ports     = ["123"]
    destination_addresses = ["*"]
    protocols             = ["UDP"]
  }

  rule {
    name                  = "allow-kube-api"
    source_addresses      = [var.aks_subnet_cidr]
    destination_ports     = ["443", "9000", "22"]
    destination_addresses = ["*"]
    protocols             = ["TCP"]
  }

  rule {
    name                  = "allow-http-https"
    source_addresses      = ["*"]
    destination_ports     = ["80", "443"]
    destination_addresses = ["*"]
    protocols             = ["TCP"]
  }
}

resource "azurerm_firewall_nat_rule_collection" "nat_rules" {
  name                = "${var.prefix}-nat-rules"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = var.resource_group_name
  priority            = 300
  action              = "Dnat"

  rule {
    name                  = "allow-http-to-nginx"
    source_addresses      = ["*"]
    destination_ports     = ["80"]
    destination_addresses = [azurerm_public_ip.firewall_pip.ip_address]
    translated_port       = "80"
    translated_address    = var.aks_loadbalancer_ip
    protocols             = ["TCP"]
  }

  rule {
    name                  = "allow-https-to-nginx"
    source_addresses      = ["*"]
    destination_ports     = ["443"]
    destination_addresses = [azurerm_public_ip.firewall_pip.ip_address]
    translated_port       = "443"
    translated_address    = var.aks_loadbalancer_ip
    protocols             = ["TCP"]
  }

  # Add web browsing rule to ensure any HTTP traffic can pass through
  rule {
    name                  = "allow-all-web-browsing"
    source_addresses      = [var.aks_subnet_cidr]
    destination_ports     = ["80", "443"]
    destination_addresses = ["*"]
    translated_port       = "80"
    translated_address    = var.aks_loadbalancer_ip
    protocols             = ["TCP"]
  }
}