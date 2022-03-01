param vnetName string
param addressPrefix string
param subnets array = []
param dnsServers array = []
param peerName string = ''
param peerId string = ''
param peerSubscriptionId string = ''
param peerResourceGroupName string = ''
param tags object = {}
param location string = resourceGroup().location
param locationShort string


resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = [for subnet in subnets: {
  name: 'nsg-${locationShort}-${tags.environment}-${subnet.name}-001'
  location: location
}]

var Subnets = [for (subnet, i) in subnets: {
    name: 'snet-vnet-${locationShort}-${tags.environment}-${subnet.name}-001'
    properties: {
      addressPrefix: subnet.addressSpace
      networkSecurityGroup: {
        id: nsg[i].id
      }
    }
}]

resource vnet 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    dhcpOptions: {
      dnsServers: dnsServers
    }
    subnets: Subnets
  }
}

// Create peering to service vnet
resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-03-01' = if (peerName != '' && peerId != '' && peerSubscriptionId != '' && peerResourceGroupName != '') {
  name: 'peeredTo-${peerName}'
  parent: vnet
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: peerId
    }
  }
}

// Create a peering to this vnet in service vnet
module remotePeering 'virtualNetworkPeerings.bicep' = if (peerName != '' && peerId != '' && peerSubscriptionId != '' && peerResourceGroupName != '') {
  name: 'peeredTo-${vnet.name}'
  scope: resourceGroup(peerSubscriptionId, peerResourceGroupName)
  dependsOn: [
    peering
  ]
  params: {
    peerId: vnet.id
    peerName: vnet.name
    vNetName: peerName
  }
}

output vnetName string = vnet.name
output resourceId string = vnet.id
output subnets array = [for (subnet, i) in subnets: {
  id: vnet.properties.subnets[i].id
}]
