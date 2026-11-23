<p align="center">
  <a href="https://aircloud.com.pl"><img src=".github/assets/banner.png" alt="AIRCLOUD: DevOps, cloud and AI engineering" width="100%"></a>
</p>

# azure-nsg-firewall-module

**Azure NSG Firewall Terraform module — parameterised, azurerm 4.x, CI-validated.**

[![CI](https://github.com/AIRCLOUD-PL/azure-nsg-firewall-module/actions/workflows/ci.yml/badge.svg)](https://github.com/AIRCLOUD-PL/azure-nsg-firewall-module/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/AIRCLOUD-PL/azure-nsg-firewall-module?sort=semver)](https://github.com/AIRCLOUD-PL/azure-nsg-firewall-module/releases)

Enterprise-grade Azure Firewall module with comprehensive security and compliance features.

## Features

✅ **Multi-Tier Support** - Standard and Premium SKU tiers  
✅ **Advanced Rules** - Network, Application, and NAT rule collections  
✅ **Threat Intelligence** - Built-in threat detection and blocking  
✅ **IDPS** - Intrusion Detection and Prevention System (Premium)  
✅ **TLS Inspection** - Deep packet inspection for encrypted traffic  
✅ **DNS Proxy** - Centralized DNS resolution and filtering  
✅ **Forced Tunneling** - Route all traffic through firewall  
✅ **Azure Policy** - Compliance and security enforcement  

## Usage

Pin the module to a release tag:

```hcl
module "nsg_firewall" {
  source = "git::https://github.com/AIRCLOUD-PL/azure-nsg-firewall-module.git?ref=v1.0.0"

  # required inputs
  environment          = "..."
  location             = "..."
  public_ip_address_id = "..."
  resource_group_name  = "..."
  subnet_id            = "..."
}
```

All inputs and outputs are listed in the generated reference below ([Inputs](#inputs), [Outputs](#outputs)). Worked examples live in [`examples/`](examples/).

### Basic Example

```hcl
module "firewall" {
  source = "git::https://github.com/AIRCLOUD-PL/azure-firewall-module.git?ref=v1.0.0"

  name                = "fw-prod-westeurope-001"
  location            = "westeurope"
  resource_group_name = "rg-production"
  environment         = "prod"
  
  subnet_id            = azurerm_subnet.firewall.id
  public_ip_address_id = azurerm_public_ip.firewall.id
  
  sku_tier = "Standard"
  
  tags = {
    Environment = "Production"
  }
}
```

### Complete Example with Rules

```hcl
module "firewall" {
  source = "git::https://github.com/AIRCLOUD-PL/azure-firewall-module.git?ref=v1.0.0"

  name                = "fw-prod-westeurope-001"
  location            = "westeurope"
  resource_group_name = "rg-production"
  environment         = "prod"
  
  subnet_id            = azurerm_subnet.firewall.id
  public_ip_address_id = azurerm_public_ip.firewall.id
  
  sku_tier         = "Standard"
  threat_intel_mode = "Deny"
  
  # DNS Configuration
  dns_proxy_enabled = true
  dns_servers       = ["168.63.129.16"]
  
  # Network Rules
  network_rule_collections = {
    "allow-web" = {
      priority = 100
      action   = "Allow"
      rules = [
        {
          name                  = "AllowHTTP"
          source_addresses      = ["10.0.0.0/8"]
          destination_addresses = ["0.0.0.0/0"]
          destination_ports     = ["80"]
          protocols             = ["TCP"]
        },
        {
          name                  = "AllowHTTPS"
          source_addresses      = ["10.0.0.0/8"]
          destination_addresses = ["0.0.0.0/0"]
          destination_ports     = ["443"]
          protocols             = ["TCP"]
        }
      ]
    }
    
    "allow-dns" = {
      priority = 200
      action   = "Allow"
      rules = [
        {
          name              = "AllowDNS"
          source_addresses  = ["10.0.0.0/8"]
          destination_fqdns = ["*"]
          destination_ports = ["53"]
          protocols         = ["UDP"]
        }
      ]
    }
  }
  
  # Application Rules
  application_rule_collections = {
    "allow-outbound" = {
      priority = 300
      action   = "Allow"
      rules = [
        {
          name             = "AllowMicrosoft"
          source_addresses = ["10.0.0.0/8"]
          target_fqdns     = ["*.microsoft.com", "*.windows.net", "*.azure.com"]
          protocol = {
            port = "443"
            type = "Https"
          }
        },
        {
          name             = "AllowUpdates"
          source_addresses = ["10.0.0.0/8"]
          fqdn_tags        = ["WindowsUpdate"]
          protocol = {
            port = "80"
            type = "Http"
          }
        }
      ]
    }
  }
  
  # NAT Rules
  nat_rule_collections = {
    "dnat-rules" = {
      priority = 400
      action   = "Dnat"
      rules = [
        {
          name                  = "DNAT-Web"
          source_addresses      = ["*"]
          destination_addresses = [azurerm_public_ip.firewall.ip_address]
          destination_ports     = ["80"]
          protocols             = ["TCP"]
          translated_address    = "10.0.1.10"
          translated_port       = "80"
        }
      ]
    }
  }
  
  tags = {
    Environment = "Production"
    Security    = "High"
    Compliance  = "SOX"
  }
}
```

### Premium Tier Example with Advanced Security

```hcl
module "firewall_premium" {
  source = "git::https://github.com/AIRCLOUD-PL/azure-firewall-module.git?ref=v1.0.0"

  name                = "fw-prod-westeurope-001"
  location            = "westeurope"
  resource_group_name = "rg-production"
  environment         = "prod"
  
  subnet_id            = azurerm_subnet.firewall.id
  public_ip_address_id = azurerm_public_ip.firewall.id
  
  sku_tier = "Premium"
  
  # Threat Intelligence
  threat_intelligence_mode = "Alert"
  threat_intelligence_allowlist = {
    ip_addresses = ["192.168.1.1"]
    fqdns        = ["trusted.example.com"]
  }
  
  # TLS Inspection
  tls_inspection_enabled = true
  tls_certificate_key_vault_secret_id = azurerm_key_vault_certificate.firewall.secret_id
  tls_certificate_name               = "firewall-tls-cert"
  
  # Intrusion Detection
  intrusion_detection = {
    mode = "Alert"
    signature_overrides = [
      {
        id    = "2032081"
        state = "Off"
      }
    ]
    traffic_bypass = [
      {
        name                  = "BypassTrusted"
        protocol              = "TCP"
        destination_addresses = ["10.0.1.0/24"]
        destination_ports     = ["443"]
      }
    ]
  }
  
  # Rules (same as Standard tier)
  network_rule_collections     = var.network_rules
  application_rule_collections = var.application_rules
  nat_rule_collections         = var.nat_rules
  
  tags = {
    Environment = "Production"
    Tier        = "Premium"
    Security    = "Maximum"
  }
}
```

## Examples

- [Basic](./examples/basic/) - Simple firewall deployment
- [Complete](./examples/complete/) - Full rule configuration
- [Premium](examples/) - Advanced security features

## Security Features

### Network Security
- **Stateful Firewall** - Layer 4-7 packet inspection
- **Application Rules** - FQDN-based filtering
- **NAT Rules** - Destination NAT for inbound traffic
- **Threat Intelligence** - Microsoft threat feeds

### Advanced Security (Premium)
- **IDPS** - Intrusion Detection and Prevention
- **TLS Inspection** - Encrypted traffic inspection
- **URL Filtering** - Web category filtering
- **Custom Signatures** - User-defined threat detection

### Compliance & Governance
- **Azure Policy** - Automated compliance
- **Resource Locks** - Prevent accidental deletion
- **Audit Logging** - Comprehensive activity logs
- **Network Watcher** - Network diagnostics

## Version

Current version: **v1.0.0**

## License

MIT

## Reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.81.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_firewall.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall) | resource |
| [azurerm_firewall_application_rule_collection.application_rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_application_rule_collection) | resource |
| [azurerm_firewall_nat_rule_collection.nat_rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_nat_rule_collection) | resource |
| [azurerm_firewall_network_rule_collection.network_rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_network_rule_collection) | resource |
| [azurerm_firewall_policy.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy) | resource |
| [azurerm_resource_group_policy_assignment.firewall_dns_proxy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_assignment) | resource |
| [azurerm_resource_group_policy_assignment.firewall_in_vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_assignment) | resource |
| [azurerm_public_ip.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/public_ip) | data source |
| [azurerm_resource_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_rule_collections"></a> [application\_rule\_collections](#input\_application\_rule\_collections) | Map of application rule collections | <pre>map(object({<br/>    priority = number<br/>    action   = string<br/>    rules = list(object({<br/>      name             = string<br/>      source_addresses = optional(list(string), [])<br/>      source_ip_groups = optional(list(string), [])<br/>      target_fqdns     = optional(list(string), [])<br/>      fqdn_tags        = optional(list(string), [])<br/>      protocol = object({<br/>        port = string<br/>        type = string<br/>      })<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_dns_proxy_enabled"></a> [dns\_proxy\_enabled](#input\_dns\_proxy\_enabled) | Enable DNS proxy | `bool` | `false` | no |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | List of DNS servers | `list(string)` | `null` | no |
| <a name="input_enable_policy_assignments"></a> [enable\_policy\_assignments](#input\_enable\_policy\_assignments) | Enable Azure Policy assignments for this Azure Firewall | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., prod, dev, test) | `string` | n/a | yes |
| <a name="input_intrusion_detection"></a> [intrusion\_detection](#input\_intrusion\_detection) | Intrusion detection configuration (Premium tier only) | <pre>object({<br/>    mode = string<br/>    signature_overrides = optional(list(object({<br/>      id    = string<br/>      state = string<br/>    })), [])<br/>    traffic_bypass = optional(list(object({<br/>      name                  = string<br/>      protocol              = string<br/>      description           = optional(string)<br/>      destination_addresses = optional(list(string), [])<br/>      destination_ip_groups = optional(list(string), [])<br/>      destination_ports     = optional(list(string), [])<br/>      source_addresses      = optional(list(string), [])<br/>      source_ip_groups      = optional(list(string), [])<br/>    })), [])<br/>  })</pre> | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region where resources will be created | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the Azure Firewall. If null, will be auto-generated. | `string` | `null` | no |
| <a name="input_naming_prefix"></a> [naming\_prefix](#input\_naming\_prefix) | Prefix for firewall naming | `string` | `"fw"` | no |
| <a name="input_nat_rule_collections"></a> [nat\_rule\_collections](#input\_nat\_rule\_collections) | Map of NAT rule collections | <pre>map(object({<br/>    priority = number<br/>    action   = string<br/>    rules = list(object({<br/>      name                  = string<br/>      source_addresses      = optional(list(string), [])<br/>      source_ip_groups      = optional(list(string), [])<br/>      destination_addresses = list(string)<br/>      destination_ports     = list(string)<br/>      protocols             = list(string)<br/>      translated_address    = string<br/>      translated_port       = string<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_network_rule_collections"></a> [network\_rule\_collections](#input\_network\_rule\_collections) | Map of network rule collections | <pre>map(object({<br/>    priority = number<br/>    action   = string<br/>    rules = list(object({<br/>      name                  = string<br/>      source_addresses      = optional(list(string), [])<br/>      source_ip_groups      = optional(list(string), [])<br/>      destination_addresses = optional(list(string), [])<br/>      destination_ip_groups = optional(list(string), [])<br/>      destination_fqdns     = optional(list(string), [])<br/>      destination_ports     = list(string)<br/>      protocols             = list(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_private_ip_ranges"></a> [private\_ip\_ranges](#input\_private\_ip\_ranges) | List of private IP ranges | `list(string)` | `null` | no |
| <a name="input_public_ip_address_id"></a> [public\_ip\_address\_id](#input\_public\_ip\_address\_id) | ID of the public IP address for Azure Firewall | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | n/a | yes |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | SKU name for Azure Firewall | `string` | `"AZFW_VNet"` | no |
| <a name="input_sku_tier"></a> [sku\_tier](#input\_sku\_tier) | SKU tier for Azure Firewall | `string` | `"Standard"` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | ID of the subnet for Azure Firewall | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_threat_intel_mode"></a> [threat\_intel\_mode](#input\_threat\_intel\_mode) | Threat intelligence mode | `string` | `"Alert"` | no |
| <a name="input_threat_intelligence_allowlist"></a> [threat\_intelligence\_allowlist](#input\_threat\_intelligence\_allowlist) | Threat intelligence allowlist | <pre>object({<br/>    ip_addresses = optional(list(string), [])<br/>    fqdns        = optional(list(string), [])<br/>  })</pre> | `null` | no |
| <a name="input_threat_intelligence_mode"></a> [threat\_intelligence\_mode](#input\_threat\_intelligence\_mode) | Threat intelligence mode for Premium tier | `string` | `"Alert"` | no |
| <a name="input_tls_certificate_key_vault_secret_id"></a> [tls\_certificate\_key\_vault\_secret\_id](#input\_tls\_certificate\_key\_vault\_secret\_id) | Key Vault secret ID for TLS certificate | `string` | `null` | no |
| <a name="input_tls_certificate_name"></a> [tls\_certificate\_name](#input\_tls\_certificate\_name) | Name of the TLS certificate | `string` | `null` | no |
| <a name="input_tls_inspection_enabled"></a> [tls\_inspection\_enabled](#input\_tls\_inspection\_enabled) | Enable TLS inspection (Premium tier only) | `bool` | `false` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | List of availability zones | `list(string)` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_rule_collection_ids"></a> [application\_rule\_collection\_ids](#output\_application\_rule\_collection\_ids) | Map of application rule collection names to IDs |
| <a name="output_firewall_policy_id"></a> [firewall\_policy\_id](#output\_firewall\_policy\_id) | Firewall Policy ID (Premium tier only) |
| <a name="output_id"></a> [id](#output\_id) | Azure Firewall resource ID |
| <a name="output_name"></a> [name](#output\_name) | Azure Firewall name |
| <a name="output_nat_rule_collection_ids"></a> [nat\_rule\_collection\_ids](#output\_nat\_rule\_collection\_ids) | Map of NAT rule collection names to IDs |
| <a name="output_network_rule_collection_ids"></a> [network\_rule\_collection\_ids](#output\_network\_rule\_collection\_ids) | Map of network rule collection names to IDs |
| <a name="output_private_ip_address"></a> [private\_ip\_address](#output\_private\_ip\_address) | Private IP address of the Azure Firewall |
| <a name="output_public_ip_address"></a> [public\_ip\_address](#output\_public\_ip\_address) | Public IP address of the Azure Firewall |
<!-- END_TF_DOCS -->

---

## Part of the AIRCLOUD Azure module catalog

Browse all modules with usage snippets in the [module catalog](https://aircloud-pl.github.io/) or on [github.com/AIRCLOUD-PL](https://github.com/AIRCLOUD-PL). Built and maintained by [AIRCLOUD](https://aircloud.com.pl): DevOps, cloud and AI engineering. Need a hand with Azure landing zones or platform engineering? See [aircloud.com.pl/consulting](https://aircloud.com.pl/consulting).
