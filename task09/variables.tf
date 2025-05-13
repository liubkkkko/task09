variable "prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "cmtr-13f58f43-mod9"
}

variable "location" {
  description = "Azure region for resources."
  type        = string
  default     = "East US"
}

variable "existing_resource_group_name" {
  description = "Name of the existing Azure Resource Group."
  type        = string
  default     = "cmtr-13f58f43-mod9-rg"
}

variable "existing_vnet_name" {
  description = "Name of the existing Azure Virtual Network."
  type        = string
  default     = "cmtr-13f58f43-mod9-vnet"
}

variable "existing_aks_subnet_name" {
  description = "Name of the existing AKS subnet."
  type        = string
  default     = "aks-snet"
}

variable "aks_loadbalancer_ip" {
  description = "Public IP address of the AKS load balancer for NGINX service."
  type        = string
  # This value must be provided in terraform.tfvars
}

variable "firewall_subnet_address_prefix" {
  description = "Address prefix for the Azure Firewall subnet. Must be at least /26."
  type        = string
  default     = "10.0.1.0/26" # Example, ensure it doesn't overlap and is part of VNet space
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default = {
    environment = "terraform-homework"
    project     = "cmtr-mod9-firewall"
  }
}