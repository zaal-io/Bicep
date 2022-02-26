targetScope = 'subscription'

param location string
param locationShort string
param tags object = {}

param landingZoneName string
param addressPrefix string
param subnets array = []

param deployVM bool = true

@secure()
param windowsVmAdminUserName string
@secure()
param windowsVmAdminPassword string


// Deploy "landing zone" VNet Resource Group
resource landingZoneRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${locationShort}-network-${tags.costcenter}-${first(tags.environment)}-001'
  location: location
  tags: tags
}

// Deploy "landing zone" VNet
module landingZoneVnet 'virtualNetworks.bicep' = {
  name: '${landingZoneName}-vnet-deploy'
  scope: landingZoneRg
  params: {
    addressPrefix: addressPrefix
    vnetName: 'vnet-${locationShort}-${first(tags.environment)}-${landingZoneName}-001'
    subnets: subnets
    locationShort: locationShort
    location: location
    tags: tags
  }
}

// Deploy "landing zone" Server Resource Group
resource landingZoneServerRg 'Microsoft.Resources/resourceGroups@2021-04-01' = if (deployVM) {
  name: 'rg-${locationShort}-test-${tags.costcenter}-${first(tags.environment)}-001'
  location: location
  tags: tags
}

// Deploy "landing zone" Servers
module landingZoneServer 'windowsVM.bicep' = if (deployVM) {
  name: '${landingZoneName}-vm-deploy'
  scope: landingZoneServerRg
  params: {
    hostName: 'az-${locationShort}01-${tags.environment}-ms90'
    adminUserName: windowsVmAdminUserName
    adminPassword: windowsVmAdminPassword
    subnetId: landingZoneVnet.outputs.subnets[0].id
    location: location
  }
}

output resourceGroupId string = landingZoneRg.id
output resourceGroupName string = landingZoneRg.name

output vnetId string = landingZoneVnet.outputs.resourceId
output vnetName string = landingZoneVnet.outputs.vnetName
