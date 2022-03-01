// Set the target scope of the deployment (tenant,managementGroup,subscription, resourceGroup)
targetScope = 'subscription'

// Load VWAN Config file. 
//var vwanConfig = json(loadTextContent('./config/customers/parameters.json'))
var vwanConfig = json(loadTextContent('./config/customers/parameters-2region.json'))
var location = vwanConfig.defaultLocation
var locationShort = vwanConfig.defaultLocationShort
var environmentShort = first(vwanConfig.environment)
var subscriptionId = vwanConfig.subscriptionId
var firewallSolution = vwanConfig.firewallSolution.value
var tags = vwanConfig.tags

// Resource naming
var vwanName = 'vwan-network-${locationShort}-${environmentShort}-001'

// Shared Services
// Resource Group for Log Analytics Workspace
resource logrg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${locationShort}-monitoring-${tags.costcenter}-${tags.environment}-001'
  location: location
  tags: tags
}

// Log Analytics Workspace
module workspace 'modules/workspaces.bicep' = {
  scope: logrg
  name: 'workspace-deploy'
  params: {
    location: location
    name: 'law-monitoring-${locationShort}-${tags.environment}-001'
    tags: tags
  }
}

// VWAN
// Resource Group
resource vwanRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-global-network-${environmentShort}-001'
  location: location
  tags: tags
}

// Deploy Virtual VWAN
module vwan 'modules/virtualWans.bicep' = {
  scope: vwanRg
  name: 'vwan-deploy'
  params: {
    name: vwanName
    location: location
  }
}

// Deploy Virtual Hubs
module virtualHubs 'modules/virtualHubs.bicep' = [for region in vwanConfig.regions: {
  scope: vwanRg
  name: 'virtualHubs-${region.location}-deploy'
  params: {
    name: 'vwan-vhub-${region.locationShort}-${environmentShort}-001'
    addressPrefix: region.hubAddressPrefix
    location: region.location
    virtualWanId: vwan.outputs.resourceId
    tags: tags
  }
}]

// Deploy Firewall Policies for Firewall enabled hubs
module firewallPolicies 'modules/firewallPolicies.bicep' = [for (region, i) in vwanConfig.regions: if (region.deployFw && firewallSolution =~ 'AzureFw') {
  scope: vwanRg
  name: 'firewallPolicies-${region.location}-deploy'
  params: {
    parentPolicyName: 'afp-vwan-${region.locationShort}-${tags.environment}-parent-001'
    childPolicyName: 'afp-vwan-${region.locationShort}-${tags.environment}-child-001'
    location: region.location
  }
}]

// Deploy Firewalls for firewall enabled hubs
module azureFirewalls 'modules/azureFirewalls.bicep' = [for (region, i) in vwanConfig.regions: if (region.deployFw && firewallSolution =~ 'AzureFw') {
  scope: vwanRg
  name: 'azureFirewalls-${region.location}-deploy'
  params: {
    name: 'AzureFirewall-vwan-${region.locationShort}-${tags.environment}-001'
    hubId: virtualHubs[i].outputs.resourceId
    location: region.location
    fwPolicyId: region.deployFw && firewallSolution =~ 'AzureFw' ? firewallPolicies[i].outputs.childResourceId : ''
    publicIPsCount: 1
    workspaceId: workspace.outputs.resourceId
  }
}]

// KEYVAULT
// Reference to existing KeyVault
resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: 'kv-deploy-p'
  scope: resourceGroup(subscriptionId, 'rg-weu-security-0451-p-001')
}


// FORTIGATE FW
// Resource Group
resource fgtFwRg 'Microsoft.Resources/resourceGroups@2021-04-01' = [for region in vwanConfig.regions: if (region.deployFw && firewallSolution =~ 'Fortigate') {
  name: 'rg-${region.locationShort}-firewall-${tags.costcenter}-${environmentShort}-001'
  location: '${region.location}'
  tags: tags
}]

// Deploy Service VNet with NVA containing two Active Fortigate Firewalls with Internal and External LoadBalancer
module fortigates 'modules/fortigateFw-Active-Active-ELB-ILB.bicep' = [for (region, i) in vwanConfig.regions: if (region.deployFw && firewallSolution =~ 'Fortigate') {
  name: 'fortigate-${region.locationShort}-deploy'
  scope: fgtFwRg[i]
  params: {
    adminPassword: keyVault.getSecret('fortigateDeployAdminPassword')
    fortiGateNamePrefix: 'fgt-fw-${region.locationShort}-${environmentShort}'
    adminUsername: keyVault.getSecret('fortigateDeployAdminUsername')
    instanceType: 'Standard_F4s'
    fortiGateAditionalCustomData: region.fwConfig.bootstrapConfig
    acceleratedNetworking: true
    publicIPNewOrExisting: 'new'
    publicIPName: 'pip-nva-fw-${region.locationShort}-${environmentShort}-001'
    publicIPResourceGroup: 'rg-${region.locationShort}-fortigate-${tags.costcenter}-${environmentShort}-001'
    vnetNewOrExisting: 'new'
    vnetName: 'vnet-${region.locationShort}-${environmentShort}-fortigate-001'
    vnetResourceGroup: 'rg-${region.locationShort}-firewall-${tags.costcenter}-${environmentShort}-001'
    vnetAddressPrefix: region.fwConfig.AddressPrefix
    subnet1Name: 'snet-vnet-${region.locationShort}-${environmentShort}-external-001'
    subnet1Prefix: region.fwConfig.externalSubnet
    subnet1StartAddress: region.fwConfig.externalSubnetStartIp
    subnet2Name: 'snet-vnet-${region.locationShort}-${environmentShort}-internal-001'
    subnet2Prefix: region.fwConfig.internalSubnet
    subnet2StartAddress: region.fwConfig.internalSubnetStartIp
    subnet3Name: 'snet-vnet-${region.locationShort}-${environmentShort}-protected-001'
    subnet3Prefix: region.fwConfig.protectedSubnet
    fortiManager: 'no'
    fortiGateLicenseBYOLA: keyVault.getSecret('FGVM4VTM21003075')
    fortiGateLicenseBYOLB: keyVault.getSecret('FGVM4VTM21003076')
    location: region.location
  }
}]

// Get built-in route tableIds
module builtInRouteTables 'modules/defaultRouteTable.bicep' = [for (region, i) in vwanConfig.regions: {
  scope: vwanRg
  name: 'defaultRouteTable-${region.location}-Ids'
  params: {
    hubName: virtualHubs[i].outputs.resourceName
  }
}]

// Hub VNet Connection with Service VNet and NVA. If the hub has a firewall apply landing zone route table otherwise use the default
@batchSize(1)
module nvaVNetConnection 'modules/hubVirtualNetworkConnections.bicep' = [for (region, i) in vwanConfig.regions: if (region.deployFw && firewallSolution =~ 'Fortigate') {
  scope: vwanRg
  name: 'vwanhub-${region.locationShort}-service-vnetconnection-deploy'
  params: {
    hubName: virtualHubs[i].outputs.resourceName
    associatedRouteTableId: builtInRouteTables[i].outputs.defaultRouteTableResourceId
    propagatedRouteTableLabels: [
      'default'
    ]
    propagatedRouteTableIds: [
      builtInRouteTables[i].outputs.defaultRouteTableResourceId
    ]
    spokeVnets: region.landingZones
    nextHopIpAddress: fortigates[i].outputs.internalLoadBalancerIpAddress
    vnetId: fortigates[i].outputs.vNetId
    connectionName: '${virtualHubs[i].outputs.resourceName}-to-${fortigates[i].outputs.vNetName}'
  }
}]

// LANDING ZONES
// Deploy Virtual Hub Route tables for Landing Zones
module lzRouteTable 'modules/hubRouteTables.bicep' = [for (region, i) in vwanConfig.regions: {
  scope: vwanRg
  name: 'lzRouteTable-${region.location}-deploy'
  params: {
    hubName: virtualHubs[i].outputs.resourceName
    labels: [
      'landingzone'
    ]
    routes: region.deployFw && firewallSolution =~ 'AzureFw' ? [
      {
        name: 'nextHopFW'
        destinationType: 'CIDR'
        destinations: [
          '0.0.0.0/0'
        ]
        nextHopType: 'ResourceId'
        nextHop: region.deployFw && firewallSolution =~ 'AzureFw' ? azureFirewalls[i].outputs.resourceId : ''
      }
    ] : []
    routeTableName: '${region.location}-lzRouteTable'
  }
}]

// Deploy Landing Zones at subscription level but in a different subscription.
@batchSize(1)
module landingZones 'modules/landingZonesCrossSubscription.bicep' = [for (region, i) in vwanConfig.regions: {
  name: '${region.locationShort}-landingzones-deploy'
  scope: subscription(subscriptionId)
  params: {
    landingZones: region.landingZones
    location: region.location
    locationShort: region.locationShort
    vwanResourceGroupName: vwanRg.name
    hubName: virtualHubs[i].outputs.resourceName
    firewallDeployed: region.deployFw
    firewallSolution: firewallSolution
    hubBuiltInDefaultRouteTableResourceId: builtInRouteTables[i].outputs.defaultRouteTableResourceId
    hubBuiltInNoneRouteTableResourceId: builtInRouteTables[i].outputs.noneRouteTableResourceId
    landingZoneRouteTableResourceId: region.deployFw && firewallSolution =~ 'AzureFw' ? lzRouteTable[i].outputs.resourceId : builtInRouteTables[i].outputs.defaultRouteTableResourceId
    nvaServiceVnetResourceId: region.deployFw && firewallSolution =~ 'Fortigate' ? fortigates[i].outputs.vNetId : ''
    nvaServiceVnetResourceName: region.deployFw && firewallSolution =~ 'Fortigate' ? fortigates[i].outputs.vNetName : ''
    nvaServiceVnetSubscriptionId: region.deployFw && firewallSolution =~ 'Fortigate' ? subscriptionId : ''
    nvaServiceVnetResourceGroupName: region.deployFw && firewallSolution =~ 'Fortigate' ? fgtFwRg[i].name : ''
    nvaHubVnetConnectionResourceId: region.deployFw && firewallSolution =~ 'Fortigate' ? nvaVNetConnection[i].outputs.resourceId : ''
    defaultRouteNextHopIpAddress: region.deployFw && firewallSolution =~ 'Fortigate' ? fortigates[i].outputs.internalLoadBalancerIpAddress : ''
    windowsVmAdminUserName: keyVault.getSecret('windowsServerAdminUsername')
    windowsVmAdminPassword: keyVault.getSecret('windowsServerAdminPassword')
  }
}]
