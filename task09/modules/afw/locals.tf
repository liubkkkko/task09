locals {
  # Define standard naming conventions for resources based on the prefix
  firewall_name = "${var.prefix}-afw"
  pip_name      = "${var.prefix}-afw-pip"
  rt_name       = "${var.prefix}-rt"
}