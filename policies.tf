/**
 * Security configurations and policies for Azure Firewall
 */

# Azure Policy - Require Azure Firewall in VNet
resource "azurerm_resource_group_policy_assignment" "firewall_in_vnet" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "${azurerm_firewall.main.name}-firewall-in-vnet"
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/568f3197-2d3d-4e22-9d42-8e18a6a3db8e"
  display_name         = "Azure Firewall should be deployed in each virtual network"
  description          = "Ensures Azure Firewall is deployed in each VNet"

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Azure Policy - Configure Azure Firewall DNS proxy
resource "azurerm_resource_group_policy_assignment" "firewall_dns_proxy" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "${azurerm_firewall.main.name}-dns-proxy"
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/8c1d4d4e-5b6c-4c8e-8d8e-9e8f8f8f8f8f"
  display_name         = "Azure Firewall DNS proxy should be enabled"
  description          = "Ensures DNS proxy is enabled on Azure Firewall"

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Data source for resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Variables for policies
variable "enable_policy_assignments" {
  description = "Enable Azure Policy assignments for this Azure Firewall"
  type        = bool
  default     = true
}