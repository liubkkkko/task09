output "firewall_public_ip_address" {
  description = "The public IP address of the Azure Firewall."
  value       = azurerm_public_ip.firewall_pip.ip_address
}

output "firewall_private_ip_address" {
  description = "The primary private IP address of the Azure Firewall."
  value       = azurerm_firewall.afw.ip_configuration[0].private_ip_address
}

output "firewall_id" {
  description = "The ID of the Azure Firewall."
  value       = azurerm_firewall.afw.id
}

output "route_table_id" {
  description = "The ID of the Route Table configured for AKS subnet."
  value       = azurerm_route_table.rt.id
}