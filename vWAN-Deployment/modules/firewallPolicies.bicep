param location string = resourceGroup().location
param parentPolicyName string
param childPolicyName string

@allowed([
  'Off'
  'Alert'
  'Deny'
])
param threatIntelMode string = 'Deny'
/* 
param dnsServers array = []
param enableProxy bool = true 
*/

var azureFwPolicyNetworkRules = json(loadTextContent('./azureFwRules/azureFwPolicyNetworkRules.json'))
var azureFwPolicyApplicationRules = json(loadTextContent('./azureFwRules/azureFwPolicyAppRules.json'))

resource parentPolicy 'Microsoft.Network/firewallPolicies@2021-02-01' = {
  name: parentPolicyName
  location: location
  properties: {
    threatIntelMode: threatIntelMode
    sku: {
      tier: 'Standard'
    }
  }
}

resource childPolicy 'Microsoft.Network/firewallPolicies@2021-02-01' = {
  name: childPolicyName
  location: location
  properties: {
    basePolicy:{
      id: parentPolicy.id
    }
    threatIntelMode: threatIntelMode
    sku: {
      tier: 'Standard'
    }
/*     
    dnsSettings: {
      servers: dnsServers
      enableProxy: enableProxy
    } 
*/    
  }
}

resource networkRulesPolicy 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2021-03-01' = {
  parent: parentPolicy
  name: 'DefaultNetworkRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: azureFwPolicyNetworkRules
  }
}

resource applicationRulesPolicy 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2021-03-01' = {
  parent: parentPolicy
  name: 'DefaultApplicationRuleCollectionGroup'
  properties: {
    priority: 300
    ruleCollections: azureFwPolicyApplicationRules
  }
}

output parentName string = parentPolicy.name
output parentResourceId string = parentPolicy.id
output childName string = childPolicy.name
output childResourceId string = childPolicy.id
