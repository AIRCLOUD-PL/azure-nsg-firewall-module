# Azure Firewall Terraform Module

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

### Basic Example

```hcl
module "firewall" {
  source = "github.com/AIRCLOUD-PL/terraform-azurerm-firewall?ref=v1.0.0"

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
  source = "github.com/AIRCLOUD-PL/terraform-azurerm-firewall?ref=v1.0.0"

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
  source = "github.com/AIRCLOUD-PL/terraform-azurerm-firewall?ref=v1.0.0"

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

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | >= 3.80.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 3.80.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| subnet_id | Firewall subnet ID | `string` | n/a | yes |
| public_ip_address_id | Public IP ID | `string` | n/a | yes |
| sku_tier | SKU tier | `string` | `"Standard"` | no |
| network_rule_collections | Network rules | `map(object)` | `{}` | no |
| application_rule_collections | Application rules | `map(object)` | `{}` | no |
| nat_rule_collections | NAT rules | `map(object)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Firewall ID |
| name | Firewall name |
| private_ip_address | Private IP address |
| public_ip_address | Public IP address |
| firewall_policy_id | Policy ID (Premium) |

## Examples

- [Basic](./examples/basic/) - Simple firewall deployment
- [Complete](./examples/complete/) - Full rule configuration
- [Premium](./examples/premium/) - Advanced security features

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
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
