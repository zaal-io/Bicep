// Set the target scope of the deployment (tenant,managementGroup,subscription, resourceGroup)
targetScope = 'subscription'

// Load VWAN Config file. 
var vwanConfig = json(loadTextContent('./config/customers/parameters.json'))
var location = vwanConfig.defaultLocation
var locationShort = vwanConfig.defaultLocationShort
var environmentShort = vwanConfig.environmentShort
var tags = vwanConfig.tags

// Resource naming
var vwanName = 'vwan-network-${locationShort}-${environmentShort}-001'


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
