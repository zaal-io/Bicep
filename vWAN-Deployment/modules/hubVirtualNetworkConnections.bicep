param hubName string
param connectionName string
param vnetId string
param associatedRouteTableId string
param propagatedRouteTableLabels array = []
param propagatedRouteTableIds array = []

var routeTableIds = [for id in propagatedRouteTableIds: {
  id: id
}]

resource vHub 'Microsoft.Network/virtualHubs@2021-03-01' existing = {
  name: hubName
}

resource connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2021-05-01' = {
  //name: '${hubName}/${connectionName}'
  name: connectionName
  parent: vHub
  properties: {
    remoteVirtualNetwork: {
      id: vnetId
    }
    enableInternetSecurity: true
    routingConfiguration: {
      associatedRouteTable: {
        id: associatedRouteTableId
      }
      propagatedRouteTables: {
        labels: propagatedRouteTableLabels  == [] ? json('null') : propagatedRouteTableLabels
        ids: propagatedRouteTableIds  == [] ? json('null') : routeTableIds
      }
    }
  }
}

// Hack to give all route tables time to update. Creates 30 empty deployments.
/* @batchSize(1)
module wait 'wait.bicep' = [for i in range(1, 3): {
  name: 'waitingOnRoutingUpdates${i}'
  dependsOn: [
    connection
  ]
}] */
