output "azure_firewall_public_ip" {
  description = "Public IP address of the Azure Firewall."
  value       = module.azure_firewall.firewall_public_ip_address
}

output "azure_firewall_private_ip" {
  description = "Private IP address of the Azure Firewall."
  value       = module.azure_firewall.firewall_private_ip_address
}