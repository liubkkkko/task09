output "azure_firewall_public_ip" {
  description = "The public IP of the Azure Firewall"
  value       = module.afw.firewall_public_ip
}

output "azure_firewall_private_ip" {
  description = "The private IP of the Azure Firewall"
  value       = module.afw.firewall_private_ip
}