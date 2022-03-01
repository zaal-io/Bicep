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

param defaultRouteNextHopIpAddress string = ''

@secure()
param windowsVmAdminUserName string
@secure()
param windowsVmAdminPassword string

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

output landingZonesOutput array = [for (landingZone, i) in landingZones: {
  resourceGroupId: landingZonesCrossSubscription[i].outputs.resourceGroupId
  resourceGroupName: landingZonesCrossSubscription[i].outputs.resourceGroupName
}]
