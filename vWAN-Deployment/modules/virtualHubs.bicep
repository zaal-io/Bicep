param name string
@allowed([
  'Basic'
  'Standard'
])
param sku string = 'Standard'

@allowed([
  'ExpressRoute'
  'VpnGateway'
  'None'
])
@description('Specifies the prefered routing gateway')
param preferredRoutingGateway string = 'ExpressRoute'

param addressPrefix string
param virtualRouterAsn int = 0
param virtualRouterIps array = []
param virtualWanId string
param vpnGatewayId string = ''
param p2SVpnGatewayId string = ''
param expressRouteGatewayId string = ''
param azureFirewallId string = ''
param securityPartnerProviderId string = ''
param securityProviderName string = ''
param allowBranchToBranchTraffic bool = false
param tags object = {}
param location string = resourceGroup().location

//Virtual WAN Hub Resource
resource hub 'Microsoft.Network/virtualHubs@2021-03-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    virtualWan: {
      id: virtualWanId
    }
    addressPrefix: addressPrefix
    sku: sku
    virtualRouterAsn: virtualRouterAsn == 0 ? json('null') : virtualRouterAsn
    virtualRouterIps: virtualRouterIps == [] ? json('null') : virtualRouterIps
    vpnGateway: vpnGatewayId == '' ? json('null') : {
      id: vpnGatewayId
    }
    p2SVpnGateway: p2SVpnGatewayId == '' ? json('null') : {
      id: p2SVpnGatewayId
    }
    expressRouteGateway: expressRouteGatewayId == '' ? json('null') : {
      id: expressRouteGatewayId
    }
    azureFirewall: azureFirewallId == '' ? json('null') : {
      id: azureFirewallId
    }
    securityPartnerProvider: securityPartnerProviderId == '' ? json('null') : {
      id: securityPartnerProviderId
    }
    securityProviderName: securityProviderName == '' ? json('null') : securityProviderName
    allowBranchToBranchTraffic: allowBranchToBranchTraffic
    preferredRoutingGateway: preferredRoutingGateway
  }
}

output resourceId string = hub.id
output resourceName string = hub.name
output virtualRouterIps array = hub.properties.virtualRouterIps
output virtualRouterAsn int = hub.properties.virtualRouterAsn
