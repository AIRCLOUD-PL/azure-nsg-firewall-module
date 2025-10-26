output "id" {
  description = "Azure Firewall resource ID"
  value       = azurerm_firewall.main.id
}

output "name" {
  description = "Azure Firewall name"
  value       = azurerm_firewall.main.name
}

output "private_ip_address" {
  description = "Private IP address of the Azure Firewall"
  value       = azurerm_firewall.main.ip_configuration[0].private_ip_address
}

output "public_ip_address" {
  description = "Public IP address of the Azure Firewall"
  value       = data.azurerm_public_ip.main.ip_address
}

output "firewall_policy_id" {
  description = "Firewall Policy ID (Premium tier only)"
  value       = var.sku_tier == "Premium" ? azurerm_firewall_policy.main[0].id : null
}

output "network_rule_collection_ids" {
  description = "Map of network rule collection names to IDs"
  value       = { for k, v in azurerm_firewall_network_rule_collection.network_rules : k => v.id }
}

output "application_rule_collection_ids" {
  description = "Map of application rule collection names to IDs"
  value       = { for k, v in azurerm_firewall_application_rule_collection.application_rules : k => v.id }
}

output "nat_rule_collection_ids" {
  description = "Map of NAT rule collection names to IDs"
  value       = { for k, v in azurerm_firewall_nat_rule_collection.nat_rules : k => v.id }
}

# Data source for public IP
data "azurerm_public_ip" "main" {
  name                = split("/", var.public_ip_address_id)[8]
  resource_group_name = split("/", var.public_ip_address_id)[4]
}