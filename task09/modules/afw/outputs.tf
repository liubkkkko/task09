output "firewall_id" {
  description = "The ID of the Azure Firewall"
  value       = azurerm_firewall.firewall.id
}

output "firewall_name" {
  description = "The name of the Azure Firewall"
  value       = azurerm_firewall.firewall.name
}

output "firewall_private_ip" {
  description = "The private IP of the Azure Firewall"
  value       = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  description = "The public IP of the Azure Firewall"
  value       = azurerm_public_ip.firewall_pip.ip_address
}

output "route_table_id" {
  description = "The ID of the route table"
  value       = azurerm_route_table.route_table.id
}

# Додано, якщо потрібно передавати CIDR підмережі Firewall назовні
output "firewall_subnet_address_prefix" {
  description = "The address prefix of the Azure Firewall subnet."
  value       = azurerm_subnet.firewall_subnet.address_prefixes[0]
}