aks_loadbalancer_ip  = "9.169.67.163"
prefix               = "cmtr-13f58f43-mod9"
location             = "East US"
resource_group_name  = "cmtr-13f58f43-mod9-rg"
virtual_network_name = "cmtr-13f58f43-mod9-vnet"
vnet_address_space   = "10.0.0.0/16"
aks_subnet_name      = "aks-snet"
aks_subnet_cidr      = "10.0.0.0/24"
firewall_subnet_cidr = "10.0.1.0/24"
additional_app_rules = [
  "*.github.com",
  "*.githubusercontent.com",
  "ghcr.io",
  "*.azurecr.io",
  "k8s.gcr.io",
  "storage.googleapis.com",
  "apt.kubernetes.io",
  "kubernetes-charts.storage.googleapis.com",
  "*.blob.core.windows.net",
  "nginx.org"
]
tags = {
  Environment = "Production"
  Project     = "AKS-Firewall-Integration"
}