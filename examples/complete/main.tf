terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-firewall-complete-example"
  location = "westeurope"
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet-firewall-example"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "firewall" {
  name                = "pip-firewall"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

module "firewall" {
  source = "../.."

  name                = "fw-complete-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  environment         = "test"

  subnet_id            = azurerm_subnet.firewall.id
  public_ip_address_id = azurerm_public_ip.firewall.id

  sku_tier          = "Standard"
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
    Example = "Complete"
  }
}

output "firewall_id" {
  value = module.firewall.id
}

output "firewall_name" {
  value = module.firewall.name
}

output "firewall_private_ip" {
  value = module.firewall.private_ip_address
}

output "firewall_public_ip" {
  value = module.firewall.public_ip_address
}

output "network_rule_collection_ids" {
  value = module.firewall.network_rule_collection_ids
}

output "application_rule_collection_ids" {
  value = module.firewall.application_rule_collection_ids
}

output "nat_rule_collection_ids" {
  value = module.firewall.nat_rule_collection_ids
}