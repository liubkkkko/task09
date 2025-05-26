locals {
  prefix = var.prefix

  common_tags = merge(var.tags, {
    CreatedBy = "Terraform"
    Purpose   = "AKS Security"
  })

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
        "acs-mirror.azureedge.net", # Може бути замінено на packages.aks.azure.com
        # "packages.aks.azure.com", # Новіший ендпоінт
        "*.docker.io",
        "*.docker.com",
        "production.cloudflare.docker.com",
        "auth.docker.io",
        "registry-1.docker.io",
        "*azurecr.io",
        "*cdn.mscr.io",
        "*.blob.core.windows.net",
        "*.trafficmanager.net",
        "*.ubuntu.com", # Для оновлень ОС вузлів
        "security.ubuntu.com",
        "azure.archive.ubuntu.com",
        "changelogs.ubuntu.com",
        "*.ods.opinsights.azure.com", # Для Azure Monitor
        "*.oms.opinsights.azure.com", # Для Azure Monitor
        "dc.services.visualstudio.com"  # Для Azure Monitor
      ]
      protocols = [
        { port = "443", type = "Https" },
        { port = "80", type = "Http" } # Для деяких репозиторіїв пакетів
      ]
    },
    {
      name             = "allow-additional-fqdns"
      description      = "Allow user-defined additional FQDNs"
      source_addresses = [var.aks_subnet_cidr]
      target_fqdns     = var.additional_app_rules # nginx.org та інші з terraform.tfvars
      protocols = [
        { port = "443", type = "Https" },
        { port = "80", type = "Http" }
      ]
    }
    # Прибрано правило "allow-all-web-browsing", якщо не є строго необхідним для тесту
  ]

  network_rule_definitions = [
    {
      name                  = "allow-dns"
      description           = "Allow DNS traffic from AKS to Azure DNS"
      source_addresses      = [var.aks_subnet_cidr]
      destination_ports     = ["53"]
      destination_addresses = ["168.63.129.16"] # Azure Public DNS
      protocols             = ["UDP", "TCP"]
    },
    {
      name                  = "allow-ntp"
      description           = "Allow NTP traffic for time synchronization"
      source_addresses      = [var.aks_subnet_cidr]
      destination_ports     = ["123"]
      # ntp.ubuntu.com є FQDN, краще його в Application Rule або використати * для Network Rule, якщо це припустимо
      destination_addresses = ["*"] # Або конкретні NTP IP, якщо відомі, або ntp.ubuntu.com в AppRule
      protocols             = ["UDP"]
    },
    {
      name                  = "allow-aks-controlplane-communication" # Більш специфічна назва
      description           = "Allow essential TCP traffic from AKS to Azure control plane services"
      source_addresses      = [var.aks_subnet_cidr]
      destination_ports     = ["443", "9000", "1194"] # Додано 1194 UDP, хоча це UDP, TCP для 443/9000
      destination_addresses = ["AzureCloud"]          # Сервісний тег для всіх публічних IP Azure
      protocols             = ["TCP"]                 # Для 443, 9000
    },
    # Додаткове правило для UDP 1194, якщо потрібно
    {
      name                  = "allow-aks-controlplane-udp"
      description           = "Allow essential UDP traffic from AKS to Azure control plane services"
      source_addresses      = [var.aks_subnet_cidr]
      destination_ports     = ["1194"]
      destination_addresses = ["AzureCloud"]
      protocols             = ["UDP"]
    }
    # Прибрано правило "allow-http-https" з destination_addresses = ["*"]
  ]

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