variable "prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "location" {
  description = "The Azure Region in which all resources should be created"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "virtual_network_name" {
  description = "The name of the virtual network"
  type        = string
}

variable "vnet_address_space" {
  description = "The address space of the virtual network"
  type        = string
}

variable "aks_subnet_name" {
  description = "The name of the AKS subnet"
  type        = string
}

variable "aks_subnet_cidr" {
  description = "The CIDR block for AKS subnet"
  type        = string
}

variable "firewall_subnet_cidr" {
  description = "The CIDR block for Azure Firewall subnet"
  type        = string
}

variable "aks_loadbalancer_ip" {
  description = "Public IP of the AKS Loadbalancer"
  type        = string
}

variable "additional_app_rules" {
  description = "Additional application rules for Azure Firewall"
  type        = list(string)
}

variable "tags" {
  description = "A mapping of tags to assign to the resources"
  type        = map(string)
}