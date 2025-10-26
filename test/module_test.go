package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestFirewallModuleBasic(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",

		Vars: map[string]interface{}{
			"resource_group_name":   "rg-test-firewall-basic",
			"location":             "westeurope",
			"environment":          "test",
			"subnet_id":            "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/AzureFirewallSubnet",
			"public_ip_address_id": "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip-firewall",
		},

		PlanOnly: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	planStruct := terraform.InitAndPlan(t, terraformOptions)

	terraform.RequirePlannedValuesMapKeyExists(t, planStruct, "azurerm_firewall.main")
}

func TestFirewallModuleWithRules(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/complete",

		Vars: map[string]interface{}{
			"resource_group_name":   "rg-test-firewall-rules",
			"location":             "westeurope",
			"environment":          "test",
			"subnet_id":            "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/AzureFirewallSubnet",
			"public_ip_address_id": "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip-firewall",
			"network_rule_collections": map[string]interface{}{
				"allow-web": map[string]interface{}{
					"priority": 100,
					"action":   "Allow",
					"rules": []map[string]interface{}{
						{
							"name":              "AllowHTTP",
							"destination_ports": []string{"80"},
							"protocols":        []string{"TCP"},
							"source_addresses": []string{"10.0.0.0/8"},
						},
					},
				},
			},
			"application_rule_collections": map[string]interface{}{
				"allow-outbound": map[string]interface{}{
					"priority": 200,
					"action":   "Allow",
					"rules": []map[string]interface{}{
						{
							"name":         "AllowMicrosoft",
							"target_fqdns": []string{"*.microsoft.com"},
							"protocol": map[string]interface{}{
								"port": "443",
								"type": "Https",
							},
							"source_addresses": []string{"10.0.0.0/8"},
						},
					},
				},
			},
		},

		PlanOnly: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	planStruct := terraform.InitAndPlan(t, terraformOptions)

	terraform.RequirePlannedValuesMapKeyExists(t, planStruct, "azurerm_firewall_network_rule_collection.network_rules")
	terraform.RequirePlannedValuesMapKeyExists(t, planStruct, "azurerm_firewall_application_rule_collection.application_rules")
}

func TestFirewallModulePremiumTier(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/premium",

		Vars: map[string]interface{}{
			"resource_group_name":   "rg-test-firewall-premium",
			"location":             "westeurope",
			"environment":          "test",
			"sku_tier":             "Premium",
			"subnet_id":            "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/AzureFirewallSubnet",
			"public_ip_address_id": "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip-firewall",
			"threat_intelligence_mode": "Alert",
			"intrusion_detection": map[string]interface{}{
				"mode": "Alert",
			},
		},

		PlanOnly: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	planStruct := terraform.InitAndPlan(t, terraformOptions)

	terraform.RequirePlannedValuesMapKeyExists(t, planStruct, "azurerm_firewall_policy.main")
}

func TestFirewallModuleNamingConvention(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",

		Vars: map[string]interface{}{
			"resource_group_name":   "rg-test-firewall-naming",
			"location":             "westeurope",
			"environment":          "prod",
			"naming_prefix":        "fwprod",
			"subnet_id":            "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/AzureFirewallSubnet",
			"public_ip_address_id": "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip-firewall",
		},

		PlanOnly: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	planStruct := terraform.InitAndPlan(t, terraformOptions)

	resourceChanges := terraform.GetResourceChanges(t, planStruct)

	for _, change := range resourceChanges {
		if change.Type == "azurerm_firewall" && change.Change.After != nil {
			afterMap := change.Change.After.(map[string]interface{})
			if name, ok := afterMap["name"]; ok {
				firewallName := name.(string)
				assert.Contains(t, firewallName, "prod", "Firewall name should contain environment")
			}
		}
	}
}

func TestFirewallModuleSecurity(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/complete",

		Vars: map[string]interface{}{
			"resource_group_name":   "rg-test-firewall-security",
			"location":             "westeurope",
			"environment":          "test",
			"threat_intel_mode":    "Deny",
			"subnet_id":            "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/AzureFirewallSubnet",
			"public_ip_address_id": "/subscriptions/sub/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip-firewall",
		},

		PlanOnly: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	planStruct := terraform.InitAndPlan(t, terraformOptions)

	resourceChanges := terraform.GetResourceChanges(t, planStruct)

	for _, change := range resourceChanges {
		if change.Type == "azurerm_firewall" && change.Change.After != null {
			afterMap := change.Change.After.(map[string]interface{})
			if threatIntel, ok := afterMap["threat_intel_mode"]; ok {
				assert.Equal(t, "Deny", threatIntel, "Threat intelligence should be set to Deny")
			}
		}
	}
}