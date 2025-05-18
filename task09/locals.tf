locals {
  prefix = var.prefix

  common_tags = merge(var.tags, {
    CreatedBy = "Terraform"
    Purpose   = "AKS Security"
  })

  # Updated Application Rules to ensure access to necessary resources
  application_rule_definitions = [
    {
      name             = "allow-aks-required-fqdns"
      description      = "Allow AKS required FQDNs and common container registries"
      source_addresses = [var.aks_subnet_cidr]
      target_fqdns = [
        "*.hcp.eastus.azmk8s.io",
        "*.azmk8s.io",
        "*.kubernetes.azure.com",
        "mcr.microsoft.com",
        "*.data.mcr.microsoft.com",
        "management.azure.com",
        "login.microsoftonline.com",
        "packages.microsoft.com",
        "acs-mirror.azureedge.net",
        "*.docker.io",
        "*.docker.com",
        "production.cloudflare.docker.com",
        "auth.docker.io",
        "registry-1.docker.io",
        "*azurecr.io",
        "*cdn.mscr.io",
        "*.blob.core.windows.net",
        "*.trafficmanager.net",
        "*.ubuntu.com",
        "security.ubuntu.com",
        "azure.archive.ubuntu.com",
        "changelogs.ubuntu.com",
        "*.ods.opinsights.azure.com",
        "*.oms.opinsights.azure.com",
        "dc.services.visualstudio.com"
      ]
      protocols = [
        { port = "443", type = "Https" },
        { port = "80", type = "Http" }
      ]
    },
    {
      name             = "allow-additional-fqdns"
      description      = "Allow user-defined additional FQDNs"
      source_addresses = [var.aks_subnet_cidr]
      target_fqdns     = var.additional_app_rules
      protocols = [
        { port = "443", type = "Https" },
        { port = "80", type = "Http" }
      ]
    },
    {
      name             = "allow-all-web-browsing"
      description      = "Allow all web traffic for testing"
      source_addresses = ["*"]
      target_fqdns     = ["*"]
      protocols = [
        { port = "443", type = "Https" },
        { port = "80", type = "Http" }
      ]
    }
  ]

  # Updated Network Rules to ensure proper connectivity
  network_rule_definitions = [
    {
      name                  = "allow-dns"
      description           = "Allow DNS traffic from AKS"
      source_addresses      = [var.aks_subnet_cidr]
      destination_ports     = ["53"]
      destination_addresses = ["168.63.129.16", "*"]
      protocols             = ["UDP", "TCP"]
    },
    {
      name                  = "allow-ntp"
      description           = "Allow NTP traffic for time synchronization"
      source_addresses      = [var.aks_subnet_cidr]
      destination_ports     = ["123"]
      destination_addresses = ["*"]
      protocols             = ["UDP"]
    },
    {
      name                  = "allow-kube-api-controlplane"
      description           = "Allow essential TCP traffic from AKS to Azure control plane services"
      source_addresses      = [var.aks_subnet_cidr]
      destination_ports     = ["443", "9000"]
      destination_addresses = ["AzureCloud"]
      protocols             = ["TCP"]
    },
    {
      name                  = "allow-http-https"
      description           = "Allow HTTP/HTTPS from and to AKS subnet"
      source_addresses      = ["*"]
      destination_ports     = ["80", "443"]
      destination_addresses = ["*"]
      protocols             = ["TCP"]
    }
  ]

  # Updated NAT Rules with proper configuration for NGINX access
  nat_rule_definitions = [
    {
      name               = "allow-http-to-nginx"
      description        = "DNAT HTTP traffic to NGINX service"
      source_addresses   = ["*"]
      destination_ports  = ["80"]
      translated_port    = "80"
      translated_address = var.aks_loadbalancer_ip
      protocols          = ["TCP"]
    },
    {
      name               = "allow-https-to-nginx"
      description        = "DNAT HTTPS traffic to NGINX service"
      source_addresses   = ["*"]
      destination_ports  = ["443"]
      translated_port    = "443"
      translated_address = var.aks_loadbalancer_ip
      protocols          = ["TCP"]
    }
  ]
}