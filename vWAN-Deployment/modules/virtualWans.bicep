param name string
@allowed([
  'Standard'
  'Basic'
])
param wanType string = 'Standard'
param disableVpnEncryption bool = false
param allowBranchToBranchTraffic bool = true
param allowVnetToVnetTraffic bool = true
param location string = resourceGroup().location
param tags object = {}

//Virtual WAN Resource
resource vwan 'Microsoft.Network/virtualWans@2021-03-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    type: wanType
    disableVpnEncryption: disableVpnEncryption
    allowBranchToBranchTraffic: allowBranchToBranchTraffic
    allowVnetToVnetTraffic: allowVnetToVnetTraffic
  }
}

output resourceId string = vwan.id
output name string = vwan.name
