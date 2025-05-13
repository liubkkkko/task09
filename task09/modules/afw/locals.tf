locals {
  firewall_subnet_name           = "AzureFirewallSubnet" // This name is mandatory for Azure Firewall
  firewall_name                  = "${var.prefix}-afw"
  firewall_pip_name              = "${var.prefix}-afw-pip"
  route_table_name               = "${var.prefix}-rt"
  app_rule_collection_name       = "${var.prefix}-afw-apprc" // Azure Firewall Application Rule Collection
  network_rule_collection_name   = "${var.prefix}-afw-netrc" // Azure Firewall Network Rule Collection
  nat_rule_collection_name       = "${var.prefix}-afw-natrc" // Azure Firewall NAT Rule Collection

  // Application rules for essential AKS egress traffic
  aks_application_rules = [
    {
      name             = "AKSEssentials"
      description      = "Allow AKS required FQDNs for control plane, MCR, and Azure auth/management."
      source_addresses = var.aks_subnet_address_prefixes
      target_fqdns     = ["*.azmk8s.io", "*.kubernetes.azure.com", "mcr.microsoft.com", "*.cdn.mscr.io", "*.data.mcr.microsoft.com", "management.azure.com", "login.microsoftonline.com"]
      protocols = [
        { type = "Https", port = 443 }
      ]
    },
    {
      name             = "AKSNodeOSUpdates"
      description      = "Allow FQDNs for AKS node OS updates (e.g., Ubuntu)."
      source_addresses = var.aks_subnet_address_prefixes
      target_fqdns     = ["*.ubuntu.com", "security.ubuntu.com", "azure.archive.ubuntu.com", "changelogs.ubuntu.com"]
      protocols = [
        { type = "Http", port = 80 },
        { type = "Https", port = 443 }
      ]
    },
    {
      name             = "AzureMonitor" # Assuming AKS might use Azure Monitor
      description      = "Allow FQDNs for Azure Monitor."
      source_addresses = var.aks_subnet_address_prefixes
      target_fqdns     = ["*.ods.opinsights.azure.com", "*.oms.opinsights.azure.com", "dc.services.visualstudio.com"]
      protocols = [
        { type = "Https", port = 443 }
      ]
    }
  ]

  // Network rules for essential AKS egress traffic
  aks_network_rules = [
    {
      name                  = "DNS"
      description           = "Allow DNS traffic to Azure DNS."
      source_addresses      = var.aks_subnet_address_prefixes
      destination_ports     = ["53"]
      destination_addresses = ["168.63.129.16"] # Azure's public DNS IP
      protocols             = ["TCP", "UDP"]
    },
    {
      name                  = "NTP"
      description           = "Allow NTP traffic for time synchronization."
      source_addresses      = var.aks_subnet_address_prefixes
      destination_ports     = ["123"]
      destination_addresses = ["*"] # For NTP, specific IPs can be regional or change; '*' is common.
      protocols             = ["UDP"]
    }
  ]
}