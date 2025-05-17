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

variable "firewall_subnet_cidr" {
  description = "The CIDR block for Azure Firewall subnet"
  type        = string
}

variable "aks_subnet_id" {
  description = "The ID of the AKS subnet"
  type        = string
}

variable "aks_subnet_cidr" { # Цей CIDR буде використовуватися як source_addresses у правилах
  description = "The CIDR block for AKS subnet"
  type        = string
}

variable "aks_loadbalancer_ip" {
  description = "Public IP of the AKS Loadbalancer"
  type        = string
}

variable "tags" {
  description = "A mapping of tags to assign to the resources"
  type        = map(string)
}

# Нові змінні для структур правил
variable "application_rule_definitions" {
  description = "A list of application rule definitions."
  type = list(object({
    name             = string
    description      = optional(string)
    source_addresses = list(string)
    target_fqdns     = list(string)
    protocols = list(object({
      port = string
      type = string
    }))
  }))
  default = []
}

variable "network_rule_definitions" {
  description = "A list of network rule definitions."
  type = list(object({
    name                  = string
    description           = optional(string)
    source_addresses      = list(string)
    destination_ports     = list(string)
    destination_addresses = list(string)
    protocols             = list(string)
  }))
  default = []
}

variable "nat_rule_definitions" {
  description = "A list of NAT rule definitions."
  type = list(object({
    name              = string
    description       = optional(string)
    source_addresses  = list(string)
    destination_ports = list(string)
    # destination_addresses не потрібен тут, він буде IP-адресою Firewall
    translated_port    = string
    translated_address = string
    protocols          = list(string)
  }))
  default = []
}