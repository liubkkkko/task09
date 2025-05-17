variable "prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "cmtr-13f58f43-mod9"
}

variable "location" {
  description = "The Azure Region in which all resources should be created"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "cmtr-13f58f43-mod9-rg"
}

variable "virtual_network_name" {
  description = "The name of the virtual network"
  type        = string
  default     = "cmtr-13f58f43-mod9-vnet"
}

variable "vnet_address_space" {
  description = "The address space of the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_subnet_name" {
  description = "The name of the AKS subnet"
  type        = string
  default     = "aks-snet"
}

variable "aks_subnet_cidr" {
  description = "The CIDR block for AKS subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "firewall_subnet_cidr" {
  description = "The CIDR block for Azure Firewall subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "aks_loadbalancer_ip" {
  description = "Public IP of the AKS Loadbalancer"
  type        = string
}

variable "additional_app_rules" {
  description = "Additional application rules for Azure Firewall"
  type        = list(string)
  default = [
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
}

variable "tags" {
  description = "A mapping of tags to assign to the resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Project     = "AKS-Firewall-Integration"
  }
}