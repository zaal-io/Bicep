targetScope = 'subscription'

param location string
param locationShort string
param tags object = {}

param landingZoneName string
param addressPrefix string
param subnets array = []

param deployVM bool = true


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

// Reference to existing KeyVault
resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: 'kv-deploy-p'
  scope: resourceGroup('17a430a4-b126-44e3-ac2c-e2da167eb708', 'rg-weu-security-0451-p-001')
}

// Deploy "landing zone" Servers
module landingZoneServer 'windowsVM.bicep' = if (deployVM) {
  name: '${landingZoneName}-vm-deploy'
  scope: landingZoneServerRg
  params: {
    hostName: 'az-${locationShort}01-${tags.environment}-ms90'
    adminUserName: 'huismanadm'
    adminPassword: keyVault.getSecret('fortigateDeployAdminPassword')
    subnetId: landingZoneVnet.outputs.subnets[0].id
    location: location
  }
}

output resourceGroupId string = landingZoneRg.id
output resourceGroupName string = landingZoneRg.name

output vnetId string = landingZoneVnet.outputs.resourceId
output vnetName string = landingZoneVnet.outputs.vnetName
