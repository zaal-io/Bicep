param location string = resourceGroup().location
@maxLength(15)
param hostName string
param subnetId string

@secure()
param adminUserName string

@secure()
param adminPassword string

param windowsOsVersion string = '2022-Datacenter'
param vmSize string = 'Standard_B2ms'
param createPublicIP bool = false

var vmName = 'vm-${hostName}'
var nicName = 'nic-lan-${vmName}-001'
var osDiskName = 'disk-${vmName}-os'
var pipName = 'pip-${vmName}-001'

resource publicIP 'Microsoft.Network/publicIPAddresses@2017-09-01' = if (createPublicIP) {
  name: pipName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
          publicIPAddress: any(createPublicIP ? {
            id : publicIP.id
          } : json('null'))
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName
  location: location
  properties: {
    licenseType: 'Windows_Server'
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: hostName
      adminUsername: adminUserName
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsOsVersion
        version: 'latest'
      }
      osDisk: {
        name: osDiskName
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

output vmNameOut string = vmName
output vmPrivateIP string = nic.properties.ipConfigurations[0].properties.privateIPAddress
