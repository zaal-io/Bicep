@description('Username for the FortiGate VM')
@secure()
param adminUsername string

@description('Password for the FortiGate VM')
@secure()
param adminPassword string

@description('Name for FortiGate virtual appliances (A & B will be appended to the end of each respectively).')
param fortiGateNamePrefix string

@description('Identifies whether to to use PAYG (on demand licensing) or BYOL license model (where license is purchased separately)')
@allowed([
  'fortinet_fg-vm'
  'fortinet_fg-vm_payg_20190624'
])
param fortiGateImageSKU string = 'fortinet_fg-vm'

@description('Select the image version')
@allowed([
  '6.2.0'
  '6.2.2'
  '6.2.4'
  '6.2.5'
  '6.4.0'
  '6.4.2'
  '6.4.3'
  '6.4.5'
  '7.0.0'
  'latest'
])
param fortiGateImageVersion string = 'latest'

@description('The ARM template provides a basic configuration. Additional configuration can be added here.')
param fortiGateAditionalCustomData string = ''

@description('Virtual Machine size selection')
@allowed([
  'Standard_F1s'
  'Standard_F2s'
  'Standard_F4s'
  'Standard_F8s'
  'Standard_F16s'
  'Standard_F1'
  'Standard_F2'
  'Standard_F4'
  'Standard_F8'
  'Standard_F16'
  'Standard_F2s_v2'
  'Standard_F4s_v2'
  'Standard_F8s_v2'
  'Standard_F16s_v2'
  'Standard_F32s_v2'
  'Standard_DS1_v2'
  'Standard_DS2_v2'
  'Standard_DS3_v2'
  'Standard_DS4_v2'
  'Standard_DS5_v2'
  'Standard_D2s_v3'
  'Standard_D4s_v3'
  'Standard_D8s_v3'
  'Standard_D16s_v3'
  'Standard_D32s_v3'
])
param instanceType string = 'Standard_F2s'

@description('Accelerated Networking enables direct connection between the VM and network card. Only available on 2 CPU F/Fs and 4 CPU D/Dsv2, D/Dsv3, E/Esv3, Fsv2, Lsv2, Ms/Mms and Ms/Mmsv2')
@allowed([
  false
  true
])
param acceleratedNetworking bool = true

@description('Identify if to use a public IP, and if so whether it\'s new')
@allowed([
  'new'
  'existing'
])
param publicIPNewOrExisting string = 'new'

@description('Name of Public IP address 1')
param publicIPName string = 'FGTLBPublicIP'

@description('Resource group to which the Public IP belongs.')
param publicIPResourceGroup string = ''

@description('Identify whether to use a new or existing vnet')
@allowed([
  'new'
  'existing'
])
param vnetNewOrExisting string = 'new'

@description('Name of the Azure virtual network.')
param vnetName string = ''

@description('Resource Group containing the virtual network - or new resource group from above (if new vnet)')
param vnetResourceGroup string = ''

@description('Virtual Network Address prefix')
param vnetAddressPrefix string = '172.16.136.0/22'

@description('Subnet 1 Name')
param subnet1Name string = 'ExternalSubnet'

@description('Subnet 1 Prefix')
param subnet1Prefix string = '172.16.136.0/26'

@description('Subnet 1 start address, 2 consecutive private IPs are required')
param subnet1StartAddress string = '172.16.136.4'

@description('Subnet 2 Name')
param subnet2Name string = 'InternalSubnet'

@description('Subnet 2 Prefix')
param subnet2Prefix string = '172.16.136.64/26'

@description('Subnet 2 start address, 2 consecutive private IPs are required')
param subnet2StartAddress string = '172.16.136.68'

@description('Subnet 3 Name')
param subnet3Name string = 'ProtectedSubnet'

@description('Subnet 3 Prefix')
param subnet3Prefix string = '172.16.137.0/24'

@description('Connect to FortiManager')
@allowed([
  'yes'
  'no'
])
param fortiManager string = 'no'

@description('FortiManager IP or DNS name to connect to on port TCP/541')
param fortiManagerIP string = ''

@description('FortiManager serial number to add the deployed FortiGate into the FortiManager')
param fortiManagerSerial string = ''

@description('Primary FortiGate BYOL license content')
@secure()
param fortiGateLicenseBYOLA string = ''

@description('Secondary FortiGate BYOL license content')
@secure()
param fortiGateLicenseBYOLB string = ''

@description('Location for all resources.')
param location string = resourceGroup().location
param fortinetTags object = {
  publisher: 'Fortinet'
  template: 'Active-Active-ELB-ILB'
  provider: '6EB3B02F-50E5-4A3E-8CB8-2E12925831AA'
}

var imagePublisher = 'fortinet'
var imageOffer = 'fortinet_fortigate-vm_v5'
var vnetName_var = ((vnetName == '') ? '${fortiGateNamePrefix}-VNET' : vnetName)
var subnet1Id = ((vnetNewOrExisting == 'new') ? resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnet1Name) : resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnet1Name))
var subnet2Id = ((vnetNewOrExisting == 'new') ? resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnet2Name) : resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnetName_var, subnet2Name))
var fgaVmName_var = '${fortiGateNamePrefix}-FGT-A'
var fgbVmName_var = '${fortiGateNamePrefix}-FGT-B'
var fmgCustomData = ((fortiManager == 'yes') ? '\nconfig system central-management\nset type fortimanager\n set fmg ${fortiManagerIP}\nset serial-number ${fortiManagerSerial}\nend\n config system interface\n edit port1\n append allowaccess fgfm\n end\n config system interface\n edit port2\n append allowaccess fgfm\n end\n' : '')
var customDataHeader = 'Content-Type: multipart/mixed; boundary="12345"\nMIME-Version: 1.0\n--12345\nContent-Type: text/plain; charset="us-ascii"\nMIME-Version: 1.0\nContent-Transfer-Encoding: 7bit\nContent-Disposition: attachment; filename="config"\n\n'
var fgaCustomDataBody = 'config system sdn-connector\nedit AzureSDN\nset type azure\nnext\nend\nconfig router static\n edit 1\n set gateway ${sn1GatewayIP}\n set device port1\n next\n edit 2\n set dst ${vnetAddressPrefix}\n set gateway ${sn2GatewayIP}\n set device port2\n next\n edit 3\nset dst 168.63.129.16 255.255.255.255\nset device port2\n set gateway ${sn2GatewayIP}\n next\nedit 4\nset dst 168.63.129.16 255.255.255.255\nset device port1\n set gateway ${sn1GatewayIP}\n next\n end\n config system probe-response\n set mode http-probe\n end\n config system interface\n edit port1\n set mode static\n set ip ${sn1IPfga}/${sn1CIDRmask}\n set description external\n set allowaccess ping ssh https probe-response\n next\n edit port2\n set mode static\n set ip ${sn2IPfga}/${sn2CIDRmask}\n set description internal\n set allowaccess ping ssh https probe-response\n next\n end\n${fmgCustomData}${fortiGateAditionalCustomData}\n'
var fgbCustomDataBody = 'config system sdn-connector\nedit AzureSDN\nset type azure\nnext\nend\nconfig router static\n edit 1\n set gateway ${sn1GatewayIP}\n set device port1\n next\n edit 2\n set dst ${vnetAddressPrefix}\n set gateway ${sn2GatewayIP}\n set device port2\n next\n edit 3\nset dst 168.63.129.16 255.255.255.255\nset device port2\n set gateway ${sn2GatewayIP}\n next\nedit 4\nset dst 168.63.129.16 255.255.255.255\nset device port1\n set gateway ${sn1GatewayIP}\n next\n end\n config system probe-response\n set mode http-probe\n end\n config system interface\n edit port1\n set mode static\n set ip ${sn1IPfgb}/${sn1CIDRmask}\n set description external\n set allowaccess ping ssh https probe-response\n next\n edit port2\n set mode static\n set ip ${sn2IPfgb}/${sn2CIDRmask}\n set description internal\n set allowaccess ping ssh https probe-response\n next\n end\n${fmgCustomData}${fortiGateAditionalCustomData}\n'
var customDataLicenseHeader = '--12345\nContent-Type: text/plain; charset="us-ascii"\nMIME-Version: 1.0\nContent-Transfer-Encoding: 7bit\nContent-Disposition: attachment; filename="fgtlicense"\n\n'
var customDataFooter = '--12345--\n'
var fgaCustomDataCombined = '${customDataHeader}${fgaCustomDataBody}${customDataLicenseHeader}${fortiGateLicenseBYOLA}${customDataFooter}'
var fgbCustomDataCombined = '${customDataHeader}${fgbCustomDataBody}${customDataLicenseHeader}${fortiGateLicenseBYOLB}${customDataFooter}'
var fgaCustomData = base64(((fortiGateLicenseBYOLA == '') ? fgaCustomDataBody : fgaCustomDataCombined))
var fgbCustomData = base64(((fortiGateLicenseBYOLB == '') ? fgbCustomDataBody : fgbCustomDataCombined))
var routeTable3Name_var = '${fortiGateNamePrefix}-${subnet3Name}-RouteTable'
var routeTable3Id = routeTable3Name.id
var fgaNic1Name_var = '${fgaVmName_var}-Nic0'
var fgaNic1Id = fgaNic1Name.id
var fgaNic2Name_var = '${fgaVmName_var}-Nic1'
var fgaNic2Id = fgaNic2Name.id
var fgbNic1Name_var = '${fgbVmName_var}-Nic0'
var fgbNic1Id = fgbNic1Name.id
var fgbNic2Name_var = '${fgbVmName_var}-Nic1'
var fgbNic2Id = fgbNic2Name.id
var publicIPName_var = ((publicIPName == '') ? '${fortiGateNamePrefix}-FGT-PIP' : publicIPName)
var publicIPId = ((publicIPNewOrExisting == 'new') ? publicIPName_resource.id : resourceId(publicIPResourceGroup, 'Microsoft.Network/publicIPAddresses', publicIPName_var))
var nsgName_var = '${fortiGateNamePrefix}-NSG-Allow-All'
var nsgId = nsgName.id
var sn1IPArray = split(subnet1Prefix, '.')
var sn1IPArray2ndString = string(sn1IPArray[3])
var sn1IPArray2nd = split(sn1IPArray2ndString, '/')
var sn1CIDRmask = string(int(sn1IPArray2nd[1]))
var sn1IPArray3 = string((int(sn1IPArray2nd[0]) + 1))
var sn1IPArray2 = string(int(sn1IPArray[2]))
var sn1IPArray1 = string(int(sn1IPArray[1]))
var sn1IPArray0 = string(int(sn1IPArray[0]))
var sn1GatewayIP = '${sn1IPArray0}.${sn1IPArray1}.${sn1IPArray2}.${sn1IPArray3}'
var sn1IPStartAddress = split(subnet1StartAddress, '.')
var sn1IPfga = '${sn1IPArray0}.${sn1IPArray1}.${sn1IPArray2}.${int(sn1IPStartAddress[3])}'
var sn1IPfgb = '${sn1IPArray0}.${sn1IPArray1}.${sn1IPArray2}.${(int(sn1IPStartAddress[3]) + 1)}'
var sn2IPArray = split(subnet2Prefix, '.')
var sn2IPArray2ndString = string(sn2IPArray[3])
var sn2IPArray2nd = split(sn2IPArray2ndString, '/')
var sn2CIDRmask = string(int(sn2IPArray2nd[1]))
var sn2IPArray3 = string((int(sn2IPArray2nd[0]) + 1))
var sn2IPArray2 = string(int(sn2IPArray[2]))
var sn2IPArray1 = string(int(sn2IPArray[1]))
var sn2IPArray0 = string(int(sn2IPArray[0]))
var sn2GatewayIP = '${sn2IPArray0}.${sn2IPArray1}.${sn2IPArray2}.${sn2IPArray3}'
var sn2IPStartAddress = split(subnet2StartAddress, '.')
var sn2IPlb = '${sn2IPArray0}.${sn2IPArray1}.${sn2IPArray2}.${int(sn2IPStartAddress[3])}'
var sn2IPfga = '${sn2IPArray0}.${sn2IPArray1}.${sn2IPArray2}.${(int(sn2IPStartAddress[3]) + 1)}'
var sn2IPfgb = '${sn2IPArray0}.${sn2IPArray1}.${sn2IPArray2}.${(int(sn2IPStartAddress[3]) + 2)}'
var internalLBName_var = '${fortiGateNamePrefix}-InternalLoadBalancer'
var internalLBFEName = '${fortiGateNamePrefix}-ILB-${subnet2Name}-FrontEnd'
var internalLBFEId = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', internalLBName_var, internalLBFEName)
var internalLBBEName = '${fortiGateNamePrefix}-ILB-${subnet2Name}-BackEnd'
var internalLBBEId = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', internalLBName_var, internalLBBEName)
var internalLBProbeName = 'lbprobe'
var internalLBProbeId = resourceId('Microsoft.Network/loadBalancers/probes', internalLBName_var, internalLBProbeName)
var externalLBName_NatRule_FGAdminPerm_fga = '${fgaVmName_var}FGAdminPerm'
var externalLBId_NatRule_FGAdminPerm_fga = resourceId('Microsoft.Network/loadBalancers/inboundNatRules', externalLBName_var, externalLBName_NatRule_FGAdminPerm_fga)
var externalLBName_NatRule_SSH_fga = '${fgaVmName_var}SSH'
var externalLBId_NatRule_SSH_fga = resourceId('Microsoft.Network/loadBalancers/inboundNatRules', externalLBName_var, externalLBName_NatRule_SSH_fga)
var externalLBName_NatRule_FGAdminPerm_fgb = '${fgbVmName_var}FGAdminPerm'
var externalLBId_NatRule_FGAdminPerm_fgb = resourceId('Microsoft.Network/loadBalancers/inboundNatRules', externalLBName_var, externalLBName_NatRule_FGAdminPerm_fgb)
var externalLBName_NatRule_SSH_fgb = '${fgbVmName_var}SSH'
var externalLBId_NatRule_SSH_fgb = resourceId('Microsoft.Network/loadBalancers/inboundNatRules', externalLBName_var, externalLBName_NatRule_SSH_fgb)
var externalLBName_var = '${fortiGateNamePrefix}-ExternalLoadBalancer'
var externalLBFEName = '${fortiGateNamePrefix}-ELB-${subnet1Name}-FrontEnd'
var externalLBFEId = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', externalLBName_var, externalLBFEName)
var externalLBBEName = '${fortiGateNamePrefix}-ELB-${subnet1Name}-BackEnd'
var externalLBBEId = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', externalLBName_var, externalLBBEName)
var externalLBProbeName = 'lbprobe'
var externalLBProbeId = resourceId('Microsoft.Network/loadBalancers/probes', externalLBName_var, externalLBProbeName)

resource vnetName_resource 'Microsoft.Network/virtualNetworks@2020-04-01' = if (vnetNewOrExisting == 'new') {
  name: vnetName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Prefix
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2Prefix
        }
      }
      {
        name: subnet3Name
        properties: {
          addressPrefix: subnet3Prefix
          routeTable: {
            id: routeTable3Id
          }
        }
      }
    ]
  }
}

resource internalLBName 'Microsoft.Network/loadBalancers@2020-04-01' = {
  name: internalLBName_var
  location: location
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: internalLBFEName
        properties: {
          privateIPAddress: sn2IPlb
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnet2Id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: internalLBBEName
      }
    ]
    loadBalancingRules: [
      {
        properties: {
          frontendIPConfiguration: {
            id: internalLBFEId
          }
          backendAddressPool: {
            id: internalLBBEId
          }
          probe: {
            id: internalLBProbeId
          }
          protocol: 'All'
          frontendPort: 0
          backendPort: 0
          enableFloatingIP: true
          idleTimeoutInMinutes: 5
        }
        name: 'lbruleFEall'
      }
    ]
    probes: [
      {
        properties: {
          protocol: 'Tcp'
          port: 8008
          intervalInSeconds: 5
          numberOfProbes: 2
        }
        name: 'lbprobe'
      }
    ]
  }
  dependsOn: [
    vnetName_resource
  ]
}

resource routeTable3Name 'Microsoft.Network/routeTables@2020-04-01' = {
  name: routeTable3Name_var
  location: location
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  properties: {
    routes: [
      {
        name: 'toDefault'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: sn2IPlb
        }
      }
    ]
  }
}

resource nsgName 'Microsoft.Network/networkSecurityGroups@2020-04-01' = {
  name: nsgName_var
  location: location
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  properties: {
    securityRules: [
      {
        name: 'AllowAllInbound'
        properties: {
          description: 'Allow all in'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAllOutbound'
        properties: {
          description: 'Allow all out'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 105
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource publicIPName_resource 'Microsoft.Network/publicIPAddresses@2020-04-01' = if (publicIPNewOrExisting == 'new') {
  name: publicIPName_var
  location: location
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource externalLBName 'Microsoft.Network/loadBalancers@2020-04-01' = {
  name: externalLBName_var
  location: location
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: externalLBFEName
        properties: {
          publicIPAddress: {
            id: publicIPId
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: externalLBBEName
      }
    ]
    loadBalancingRules: [
      {
        properties: {
          frontendIPConfiguration: {
            id: externalLBFEId
          }
          backendAddressPool: {
            id: externalLBBEId
          }
          probe: {
            id: externalLBProbeId
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: true
          idleTimeoutInMinutes: 5
        }
        name: 'ExternalLBRule-FE-http'
      }
      {
        properties: {
          frontendIPConfiguration: {
            id: externalLBFEId
          }
          backendAddressPool: {
            id: externalLBBEId
          }
          probe: {
            id: externalLBProbeId
          }
          protocol: 'Udp'
          frontendPort: 10551
          backendPort: 10551
          enableFloatingIP: true
          idleTimeoutInMinutes: 5
        }
        name: 'ExternalLBRule-FE-udp10551'
      }
    ]
    inboundNatRules: [
      {
        name: externalLBName_NatRule_SSH_fga
        properties: {
          frontendIPConfiguration: {
            id: externalLBFEId
          }
          protocol: 'Tcp'
          frontendPort: 50030
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: externalLBName_NatRule_FGAdminPerm_fga
        properties: {
          frontendIPConfiguration: {
            id: externalLBFEId
          }
          protocol: 'Tcp'
          frontendPort: 40030
          backendPort: 443
          enableFloatingIP: false
        }
      }
      {
        name: externalLBName_NatRule_SSH_fgb
        properties: {
          frontendIPConfiguration: {
            id: externalLBFEId
          }
          protocol: 'Tcp'
          frontendPort: 50031
          backendPort: 22
          enableFloatingIP: false
        }
      }
      {
        name: externalLBName_NatRule_FGAdminPerm_fgb
        properties: {
          frontendIPConfiguration: {
            id: externalLBFEId
          }
          protocol: 'Tcp'
          frontendPort: 40031
          backendPort: 443
          enableFloatingIP: false
        }
      }
    ]
    probes: [
      {
        properties: {
          protocol: 'Tcp'
          port: 8008
          intervalInSeconds: 5
          numberOfProbes: 2
        }
        name: 'lbprobe'
      }
    ]
  }
}

resource fgaNic1Name 'Microsoft.Network/networkInterfaces@2020-04-01' = {
  name: fgaNic1Name_var
  location: location
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: sn1IPfga
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnet1Id
          }
          loadBalancerBackendAddressPools: [
            {
              id: externalLBBEId
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: externalLBId_NatRule_SSH_fga
            }
            {
              id: externalLBId_NatRule_FGAdminPerm_fga
            }
          ]
        }
      }
    ]
    enableIPForwarding: true
    enableAcceleratedNetworking: acceleratedNetworking
    networkSecurityGroup: {
      id: nsgId
    }
  }
  dependsOn: [
    externalLBName
    vnetName_resource
  ]
}

resource fgbNic1Name 'Microsoft.Network/networkInterfaces@2020-04-01' = {
  name: fgbNic1Name_var
  location: location
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: sn1IPfgb
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnet1Id
          }
          loadBalancerBackendAddressPools: [
            {
              id: externalLBBEId
            }
          ]
          loadBalancerInboundNatRules: [
            {
              id: externalLBId_NatRule_SSH_fgb
            }
            {
              id: externalLBId_NatRule_FGAdminPerm_fgb
            }
          ]
        }
      }
    ]
    enableIPForwarding: true
    enableAcceleratedNetworking: acceleratedNetworking
    networkSecurityGroup: {
      id: nsgId
    }
  }
  dependsOn: [
    externalLBName
    fgaNic1Name
    vnetName_resource
  ]
}

resource fgaNic2Name 'Microsoft.Network/networkInterfaces@2020-04-01' = {
  name: fgaNic2Name_var
  location: location
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: sn2IPfga
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnet2Id
          }
          loadBalancerBackendAddressPools: [
            {
              id: internalLBBEId
            }
          ]
        }
      }
    ]
    enableIPForwarding: true
    enableAcceleratedNetworking: acceleratedNetworking
    networkSecurityGroup: {
      id: nsgId
    }
  }
  dependsOn: [
    internalLBName
    vnetName_resource
  ]
}

resource fgbNic2Name 'Microsoft.Network/networkInterfaces@2020-04-01' = {
  name: fgbNic2Name_var
  location: location
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: sn2IPfgb
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnet2Id
          }
          loadBalancerBackendAddressPools: [
            {
              id: internalLBBEId
            }
          ]
        }
      }
    ]
    enableIPForwarding: true
    enableAcceleratedNetworking: acceleratedNetworking
    networkSecurityGroup: {
      id: nsgId
    }
  }
  dependsOn: [
    internalLBName
    vnetName_resource
    fgaNic2Name
  ]
}

resource fgaVmName 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: fgaVmName_var
  location: location
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  identity: {
    type: 'SystemAssigned'
  }
  plan: {
    name: fortiGateImageSKU
    publisher: imagePublisher
    product: imageOffer
  }
  properties: {
    hardwareProfile: {
      vmSize: instanceType
    }
    osProfile: {
      computerName: fgaVmName_var
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: fgaCustomData
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: fortiGateImageSKU
        version: fortiGateImageVersion
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          diskSizeGB: 30
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary: true
          }
          id: fgaNic1Id
        }
        {
          properties: {
            primary: false
          }
          id: fgaNic2Id
        }
      ]
    }
  }
  zones: [
    '1'
  ]
}

resource fgbVmName 'Microsoft.Compute/virtualMachines@2019-07-01' = {
  name: fgbVmName_var
  location: location
  tags: {
    provider: toUpper(fortinetTags.provider)
  }
  identity: {
    type: 'SystemAssigned'
  }
  plan: {
    name: fortiGateImageSKU
    publisher: imagePublisher
    product: imageOffer
  }
  properties: {
    hardwareProfile: {
      vmSize: instanceType
    }
    osProfile: {
      computerName: fgbVmName_var
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: fgbCustomData
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: fortiGateImageSKU
        version: fortiGateImageVersion
      }
      osDisk: {
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          diskSizeGB: 30
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            primary: true
          }
          id: fgbNic1Id
        }
        {
          properties: {
            primary: false
          }
          id: fgbNic2Id
        }
      ]
    }
  }
  zones: [
    '2'
  ]
}

output vNetName string = vnetName
output vNetId string = vnetName_resource.id
output internalSubnetName string = subnet2Name
output internalLoadBalancerIpAddress string = subnet2StartAddress
output defaultRouteTableId string = routeTable3Name.id
