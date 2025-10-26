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
  name     = "rg-firewall-basic-example"
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

  name                = "fw-basic-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  environment         = "test"

  subnet_id            = azurerm_subnet.firewall.id
  public_ip_address_id = azurerm_public_ip.firewall.id

  sku_tier = "Standard"

  tags = {
    Example = "Basic"
  }
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