variable "name" {
  description = "Name of the Azure Firewall. If null, will be auto-generated."
  type        = string
  default     = null
}

variable "naming_prefix" {
  description = "Prefix for firewall naming"
  type        = string
  default     = "fw"
}

variable "environment" {
  description = "Environment name (e.g., prod, dev, test)"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for Azure Firewall"
  type        = string
}

variable "public_ip_address_id" {
  description = "ID of the public IP address for Azure Firewall"
  type        = string
}

variable "sku_name" {
  description = "SKU name for Azure Firewall"
  type        = string
  default     = "AZFW_VNet"
  validation {
    condition     = contains(["AZFW_VNet", "AZFW_Hub"], var.sku_name)
    error_message = "SKU name must be AZFW_VNet or AZFW_Hub."
  }
}

variable "sku_tier" {
  description = "SKU tier for Azure Firewall"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.sku_tier)
    error_message = "SKU tier must be Standard or Premium."
  }
}

variable "threat_intel_mode" {
  description = "Threat intelligence mode"
  type        = string
  default     = "Alert"
  validation {
    condition     = contains(["Off", "Alert", "Deny"], var.threat_intel_mode)
    error_message = "Threat intel mode must be Off, Alert, or Deny."
  }
}

variable "dns_servers" {
  description = "List of DNS servers"
  type        = list(string)
  default     = null
}

variable "dns_proxy_enabled" {
  description = "Enable DNS proxy"
  type        = bool
  default     = false
}

variable "private_ip_ranges" {
  description = "List of private IP ranges"
  type        = list(string)
  default     = null
}

variable "zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = null
}

# Rule Collections
variable "network_rule_collections" {
  description = "Map of network rule collections"
  type = map(object({
    priority = number
    action   = string
    rules = list(object({
      name                  = string
      source_addresses      = optional(list(string), [])
      source_ip_groups      = optional(list(string), [])
      destination_addresses = optional(list(string), [])
      destination_ip_groups = optional(list(string), [])
      destination_fqdns     = optional(list(string), [])
      destination_ports     = list(string)
      protocols             = list(string)
    }))
  }))
  default = {}
}

variable "application_rule_collections" {
  description = "Map of application rule collections"
  type = map(object({
    priority = number
    action   = string
    rules = list(object({
      name             = string
      source_addresses = optional(list(string), [])
      source_ip_groups = optional(list(string), [])
      target_fqdns     = optional(list(string), [])
      fqdn_tags        = optional(list(string), [])
      protocol = object({
        port = string
        type = string
      })
    }))
  }))
  default = {}
}

variable "nat_rule_collections" {
  description = "Map of NAT rule collections"
  type = map(object({
    priority = number
    action   = string
    rules = list(object({
      name                  = string
      source_addresses      = optional(list(string), [])
      source_ip_groups      = optional(list(string), [])
      destination_addresses = list(string)
      destination_ports     = list(string)
      protocols             = list(string)
      translated_address    = string
      translated_port       = string
    }))
  }))
  default = {}
}

# Premium Features
variable "threat_intelligence_mode" {
  description = "Threat intelligence mode for Premium tier"
  type        = string
  default     = "Alert"
}

variable "threat_intelligence_allowlist" {
  description = "Threat intelligence allowlist"
  type = object({
    ip_addresses = optional(list(string), [])
    fqdns        = optional(list(string), [])
  })
  default = null
}

variable "tls_inspection_enabled" {
  description = "Enable TLS inspection (Premium tier only)"
  type        = bool
  default     = false
}

variable "tls_certificate_key_vault_secret_id" {
  description = "Key Vault secret ID for TLS certificate"
  type        = string
  default     = null
}

variable "tls_certificate_name" {
  description = "Name of the TLS certificate"
  type        = string
  default     = null
}

variable "intrusion_detection" {
  description = "Intrusion detection configuration (Premium tier only)"
  type = object({
    mode = string
    signature_overrides = optional(list(object({
      id    = string
      state = string
    })), [])
    traffic_bypass = optional(list(object({
      name                  = string
      protocol              = string
      description           = optional(string)
      destination_addresses = optional(list(string), [])
      destination_ip_groups = optional(list(string), [])
      destination_ports     = optional(list(string), [])
      source_addresses      = optional(list(string), [])
      source_ip_groups      = optional(list(string), [])
    })), [])
  })
  default = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}