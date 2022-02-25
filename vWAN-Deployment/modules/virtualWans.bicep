param name string
@allowed([
  'Standard'
  'Basic'
])
param wanType string = 'Standard'
param disableVpnEncryption bool = false
param allowBranchToBranchTraffic bool = true
//param allowVnetToVnetTraffic bool = false //--vnet-to-vnet-traffic is deprecated in 2020-05-01
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
    //allowVnetToVnetTraffic: allowVnetToVnetTraffic //--vnet-to-vnet-traffic is deprecated in 2020-05-01
  }
}

output resourceId string = vwan.id
output name string = vwan.name
