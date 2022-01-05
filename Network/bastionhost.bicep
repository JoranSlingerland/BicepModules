//Paramaters
param bastionHostsName string
param bastionPipname string
param vnetName string
param location string
param bastionAddressPrefix string 
param tags object

//Deployment
resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  name: '${vnetName}/AzureBastionSubnet'
  properties: {
    addressPrefix: bastionAddressPrefix
  }
}

module pip '../network/pip.bicep' = {
  name: bastionPipname
  scope: resourceGroup()
  params: {
    tags: tags
    location: location
    name: bastionPipname
  }
}

resource bastionHosts 'Microsoft.Network/bastionHosts@2020-11-01' = {
  name: bastionHostsName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.outputs.pipId
          }
          subnet: {
            id: bastionSubnet.id
          }
        }
      }
    ]
  }
}
