// Set the target scope of the deployment (tenant,managementGroup,subscription, resourceGroup)
targetScope = 'subscription'

// Load VWAN Config file. 
var vwanConfig = json(loadTextContent('./config/customers/parameters.json'))
var location = vwanConfig.defaultLocation
