locals {
  # Define standard naming conventions for resources based on the prefix
  firewall_name = "${var.prefix}-afw"
  # Corrected PIP name convention
  pip_name = "${var.prefix}-pip"
  rt_name  = "${var.prefix}-rt"

  # Azure Firewall Subnet MUST be named "AzureFirewallSubnet"
  firewall_subnet_name = "AzureFirewallSubnet"
}