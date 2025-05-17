locals {
  prefix = var.prefix # Зберігаємо префікс

  # Resource abbreviations - можна залишити, якщо використовуються десь ще, або видалити, якщо ні
  resource_abbreviations = {
    firewall        = "afw"
    public_ip       = "pip"
    route_table     = "rt"
    virtual_network = "vnet"
    subnet          = "snet"
  }

  common_tags = merge(var.tags, {
    CreatedBy = "Terraform"
    Purpose   = "AKS Security"
  })

  # Визначення для Application Rules
  # Це дозволяє нам використовувати for_each для створення динамічних правил
  application_rule_definitions = [
    {
      name             = "allow-aks-required-fqdns"
      description      = "Allow AKS required FQDNs and common container registries"
      source_addresses = [var.aks_subnet_cidr] # Використовуємо змінну з root
      target_fqdns = [
        "*.hcp.eastus.azmk8s.io", # Специфічний для регіону AKS Control Plane
        "*.azmk8s.io",            # Загальний для AKS Control Plane
        "*.kubernetes.azure.com", # Загальний для AKS Control Plane
        "mcr.microsoft.com",
        "*.data.mcr.microsoft.com",
        "management.azure.com",
        "login.microsoftonline.com",
        "packages.microsoft.com",
        "acs-mirror.azureedge.net",
        "*.docker.io",
        "*.docker.com",
        "production.cloudflare.docker.com", # Docker Hub CDN
        "auth.docker.io",                   # Docker Hub Auth
        "registry-1.docker.io",             # Docker Hub Registry
        "*azurecr.io",                      # Azure Container Registry (загальний)
        "*cdn.mscr.io",
        "*.blob.core.windows.net",     # Azure Storage (для образів, тощо)
        "*.trafficmanager.net",        # Може знадобитися для деяких сервісів Azure
        "*.ubuntu.com",                # Оновлення для вузлів AKS
        "security.ubuntu.com",         # Оновлення безпеки
        "azure.archive.ubuntu.com",    # Архіви Ubuntu для Azure
        "changelogs.ubuntu.com",       # Журнали змін Ubuntu
        "*.ods.opinsights.azure.com",  # Azure Monitor Logs
        "*.oms.opinsights.azure.com",  # Azure Monitor OMS
        "dc.services.visualstudio.com" # Azure Monitor Application Insights
      ]
      protocols = [
        { port = "443", type = "Https" },
        { port = "80", type = "Http" } # Деякі репозиторії пакетів або дзеркала можуть використовувати HTTP
      ]
    },
    {
      name             = "allow-additional-fqdns"
      description      = "Allow user-defined additional FQDNs"
      source_addresses = [var.aks_subnet_cidr]    # Використовуємо змінну з root
      target_fqdns     = var.additional_app_rules # Змінна з root
      protocols = [
        { port = "443", type = "Https" },
        { port = "80", type = "Http" }
      ]
    }
    # Прибрано правило "allow-all-web-browsing" target_fqdns = ["*"], оскільки це занадто широко.
    # Якщо воно потрібне, його можна додати сюди аналогічно.
  ]

  # Визначення для Network Rules
  network_rule_definitions = [
    {
      name                  = "allow-dns"
      description           = "Allow DNS traffic from AKS"
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
      destination_addresses = ["*"] # Або конкретні NTP сервери, наприклад, time.windows.com, ntp.ubuntu.com
      protocols             = ["UDP"]
    },
    {
      name                  = "allow-kube-api-controlplane" # Змінено ім'я для ясності
      description           = "Allow essential TCP traffic from AKS to Azure control plane services"
      source_addresses      = [var.aks_subnet_cidr]
      destination_ports     = ["443", "9000"] # 22 (SSH) зазвичай не потрібен для вихідного трафіку AKS
      destination_addresses = ["AzureCloud"]  # Сервісний тег для всіх публічних IP Azure
      protocols             = ["TCP"]
    }
    # Прибрано правило "allow-http-https" destination_addresses = ["*"], оскільки це занадто широко.
    # Вихідний HTTP/HTTPS має контролюватися через Application Rules з конкретними FQDN.
  ]

  # Визначення для NAT Rules
  # destination_addresses для DNAT має бути IP самого Firewall
  nat_rule_definitions = [
    {
      name               = "allow-http-to-nginx"
      description        = "DNAT HTTP traffic to NGINX service"
      source_addresses   = ["*"] # Будь-хто з Інтернету
      destination_ports  = ["80"]
      translated_port    = "80"
      translated_address = var.aks_loadbalancer_ip # Використовуємо змінну з root
      protocols          = ["TCP"]
    },
    {
      name               = "allow-https-to-nginx"
      description        = "DNAT HTTPS traffic to NGINX service"
      source_addresses   = ["*"]
      destination_ports  = ["443"]
      translated_port    = "443"
      translated_address = var.aks_loadbalancer_ip # Використовуємо змінну з root
      protocols          = ["TCP"]
    }
    # Прибрано проблемне NAT-правило "allow-all-web-browsing", оскільки воно було некоректним для DNAT.
  ]
}