targetScope = 'subscription'

param location string
param locationShort string
param landingZones array = []

param firewallDeployed bool
param firewallSolution string

param vwanResourceGroupName string
param hubName string
param hubBuiltInDefaultRouteTableResourceId string
param hubBuiltInNoneRouteTableResourceId string
param landingZoneRouteTableResourceId string

param nvaServiceVnetResourceId string = ''
param nvaServiceVnetResourceName string = ''
param nvaServiceVnetSubscriptionId string = ''
param nvaServiceVnetResourceGroupName string = ''
param nvaHubVnetConnectionResourceId string = ''

param defaultRouteNextHopIpAddress string = ''

@secure()
param windowsVmAdminUserName string
@secure()
param windowsVmAdminPassword string

var landingZoneRoutesThroughNva = [for landingZone in landingZones: {
  name: 'NvaFwSpoke-${landingZone.name}'
  destinationType: 'CIDR'
  destinations: [
    '${landingZone.addressPrefix}'
  ]
  nextHopType: 'ResourceId'
  nextHop: nvaHubVnetConnectionResourceId
}]

// @batchSize(1)
module landingZonesCrossSubscription 'landingZones.bicep' = [for landingZone in landingZones: {
  name: '${landingZone.name}-rg-deploy'
  scope: subscription(landingZone.subscriptionId)
  params: {
    location: location
    locationShort: locationShort
    tags: landingZone.tags
    landingZoneName: landingZone.name
    addressPrefix: landingZone.addressPrefix
    subnets: landingZone.subnets
    deployVM: landingZone.deployVM
    windowsVmAdminUserName: windowsVmAdminUserName
    windowsVmAdminPassword: windowsVmAdminPassword
    nvaServiceVnetResourceId: nvaServiceVnetResourceId
    nvaServiceVnetResourceName: nvaServiceVnetResourceName
    nvaServiceVnetSubscriptionId: nvaServiceVnetSubscriptionId
    nvaServiceVnetResourceGroupName: nvaServiceVnetResourceGroupName
    defaultRouteNextHopIpAddress: defaultRouteNextHopIpAddress
  }
}]

// Landing Zone VNet Connection. If the hub has a firewall apply landing zone route table otherwise use the default
module lzVNetConnection 'hubVirtualNetworkConnections.bicep' = [for (landingZone, i) in landingZones: if (firewallSolution != 'Fortigate') {
  scope: resourceGroup(vwanResourceGroupName)
  name: 'vwanhub-${locationShort}-${landingZone.name}-vnetconnection-deploy'
  params: {
    hubName: hubName
    associatedRouteTableId: firewallDeployed ? landingZoneRouteTableResourceId : hubBuiltInDefaultRouteTableResourceId
    propagatedRouteTableLabels: firewallDeployed ? [
      'none'
    ] : [
      'default'
    ]
    propagatedRouteTableIds: firewallDeployed ? [
      hubBuiltInNoneRouteTableResourceId
    ] : [
      hubBuiltInDefaultRouteTableResourceId
    ]
    vnetId: landingZonesCrossSubscription[i].outputs.vnetId
    connectionName: '${hubName}-to-${landingZonesCrossSubscription[i].outputs.vnetName}'
  }
}]

// Set Virtual Hub Default Route tables with Routes for Spoke Vnets (Landing Zones)
module defaultRouteTable 'hubRouteTables.bicep' = if (firewallDeployed && firewallSolution =~ 'Fortigate') {
  scope: resourceGroup(vwanResourceGroupName)
  name: 'vwanhub-${locationShort}-defaultRouteTable-Routes'
  params: {
    hubName: hubName
    labels: [
      'default'
    ]
    routes: firewallDeployed && firewallSolution =~ 'Fortigate' ? landingZoneRoutesThroughNva : []
    routeTableName: 'defaultRouteTable'
  }
}

output landingZonesOutput array = [for (landingZone, i) in landingZones: {
  resourceGroupId: landingZonesCrossSubscription[i].outputs.resourceGroupId
  resourceGroupName: landingZonesCrossSubscription[i].outputs.resourceGroupName
}]
