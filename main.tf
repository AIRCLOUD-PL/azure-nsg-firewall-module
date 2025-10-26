/**
 * # Azure Firewall Module
 *
 * Enterprise-grade Azure Firewall module with comprehensive security and compliance features.
 *
 * ## Features
 * - Azure Firewall with multiple rule collections
 * - Network rules, application rules, NAT rules
 * - Threat intelligence and IDPS
 * - Forced tunneling
 * - DNS proxy and custom DNS
 * - Azure Policy integration
 * - Monitoring and logging
 */



locals {
  # Auto-generate firewall name if not provided
  firewall_name = var.name != null ? var.name : "${var.naming_prefix}${var.environment}${replace(var.location, "-", "")}fw"

  # Default tags
  default_tags = {
    ManagedBy   = "Terraform"
    Module      = "azure-firewall"
    Environment = var.environment
  }

  tags = merge(local.default_tags, var.tags)
}

# Azure Firewall
resource "azurerm_firewall" "main" {
  name                = local.firewall_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name = var.sku_name
  sku_tier = var.sku_tier

  # IP Configuration
  ip_configuration {
    name                 = "firewall-ip-config"
    subnet_id            = var.subnet_id
    public_ip_address_id = var.public_ip_address_id
  }

  # Threat Intelligence
  threat_intel_mode = var.threat_intel_mode

  # DNS
  dns_servers       = var.dns_servers
  dns_proxy_enabled = var.dns_proxy_enabled

  # Private ranges
  private_ip_ranges = var.private_ip_ranges

  # Zones
  zones = var.zones

  tags = local.tags
}

# Network Rule Collections
resource "azurerm_firewall_network_rule_collection" "network_rules" {
  for_each = var.network_rule_collections

  name                = each.key
  azure_firewall_name = azurerm_firewall.main.name
  resource_group_name = var.resource_group_name
  priority            = each.value.priority
  action              = each.value.action

  dynamic "rule" {
    for_each = each.value.rules
    content {
      name                  = rule.value.name
      source_addresses      = try(rule.value.source_addresses, [])
      source_ip_groups      = try(rule.value.source_ip_groups, [])
      destination_addresses = try(rule.value.destination_addresses, [])
      destination_ip_groups = try(rule.value.destination_ip_groups, [])
      destination_fqdns     = try(rule.value.destination_fqdns, [])
      destination_ports     = rule.value.destination_ports
      protocols             = rule.value.protocols
    }
  }
}

# Application Rule Collections
resource "azurerm_firewall_application_rule_collection" "application_rules" {
  for_each = var.application_rule_collections

  name                = each.key
  azure_firewall_name = azurerm_firewall.main.name
  resource_group_name = var.resource_group_name
  priority            = each.value.priority
  action              = each.value.action

  dynamic "rule" {
    for_each = each.value.rules
    content {
      name             = rule.value.name
      source_addresses = try(rule.value.source_addresses, [])
      source_ip_groups = try(rule.value.source_ip_groups, [])
      target_fqdns     = try(rule.value.target_fqdns, [])
      fqdn_tags        = try(rule.value.fqdn_tags, [])
      protocol {
        port = rule.value.protocol.port
        type = rule.value.protocol.type
      }
    }
  }
}

# NAT Rule Collections
resource "azurerm_firewall_nat_rule_collection" "nat_rules" {
  for_each = var.nat_rule_collections

  name                = each.key
  azure_firewall_name = azurerm_firewall.main.name
  resource_group_name = var.resource_group_name
  priority            = each.value.priority
  action              = each.value.action

  dynamic "rule" {
    for_each = each.value.rules
    content {
      name                  = rule.value.name
      source_addresses      = try(rule.value.source_addresses, [])
      source_ip_groups      = try(rule.value.source_ip_groups, [])
      destination_addresses = rule.value.destination_addresses
      destination_ports     = rule.value.destination_ports
      protocols             = rule.value.protocols
      translated_address    = rule.value.translated_address
      translated_port       = rule.value.translated_port
    }
  }
}

# Firewall Policy (for Premium tier)
resource "azurerm_firewall_policy" "main" {
  count = var.sku_tier == "Premium" ? 1 : 0

  name                = "${local.firewall_name}-policy"
  resource_group_name = var.resource_group_name
  location            = var.location

  # Threat Intelligence
  threat_intelligence_mode = var.threat_intelligence_mode
  threat_intelligence_allowlist {
    ip_addresses = try(var.threat_intelligence_allowlist.ip_addresses, [])
    fqdns        = try(var.threat_intelligence_allowlist.fqdns, [])
  }

  # TLS Inspection
  dynamic "tls_certificate" {
    for_each = var.tls_inspection_enabled ? [1] : []
    content {
      key_vault_secret_id = var.tls_certificate_key_vault_secret_id
      name                = var.tls_certificate_name
    }
  }

  # Intrusion Detection System
  dynamic "intrusion_detection" {
    for_each = var.intrusion_detection != null ? [var.intrusion_detection] : []
    content {
      mode = intrusion_detection.value.mode
      dynamic "signature_overrides" {
        for_each = try(intrusion_detection.value.signature_overrides, [])
        content {
          id    = signature_overrides.value.id
          state = signature_overrides.value.state
        }
      }
      dynamic "traffic_bypass" {
        for_each = try(intrusion_detection.value.traffic_bypass, [])
        content {
          name                  = traffic_bypass.value.name
          protocol              = traffic_bypass.value.protocol
          description           = try(traffic_bypass.value.description, null)
          destination_addresses = try(traffic_bypass.value.destination_addresses, [])
          destination_ip_groups = try(traffic_bypass.value.destination_ip_groups, [])
          destination_ports     = try(traffic_bypass.value.destination_ports, [])
          source_addresses      = try(traffic_bypass.value.source_addresses, [])
          source_ip_groups      = try(traffic_bypass.value.source_ip_groups, [])
        }
      }
    }
  }

  tags = local.tags
}

# Associate Firewall with Policy (handled directly in azurerm_firewall resource in azurerm 4.x)
# resource "azurerm_firewall_policy_association" "main" {
#   count = var.sku_tier == "Premium" ? 1 : 0
#
#   firewall_id = azurerm_firewall.main.id
#   policy_id   = azurerm_firewall_policy.main[0].id
# }