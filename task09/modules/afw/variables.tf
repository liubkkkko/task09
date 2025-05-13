variable "prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "location" {
  description = "Azure region for resources."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group."
  type        = string
}

variable "virtual_network_name" {
  description = "Name of the Azure Virtual Network."
  type        = string
}

variable "aks_subnet_id" {
  description = "ID of the existing AKS subnet."
  type        = string
}

variable "aks_subnet_address_prefixes" {
  description = "Address prefixes of the AKS subnet, used as source in FW rules."
  type        = list(string)
}

variable "aks_loadbalancer_ip" {
  description = "Public IP address of the AKS load balancer for NGINX service (for NAT rule)."
  type        = string
}

variable "firewall_subnet_address_prefix" {
  description = "Address prefix for the new Azure Firewall subnet."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
}