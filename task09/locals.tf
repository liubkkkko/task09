locals {
  # Common naming prefix
  prefix = var.prefix

  # Resource abbreviations as per Azure naming recommendations
  resource_abbreviations = {
    firewall        = "afw"
    public_ip       = "pip"
    route_table     = "rt"
    virtual_network = "vnet"
    subnet          = "snet"
  }

  # Tags to be applied to all resources
  common_tags = merge(var.tags, {
    CreatedBy = "Terraform"
    Purpose   = "AKS Security"
  })
}