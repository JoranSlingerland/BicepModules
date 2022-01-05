param privateEndpointName string
param location string
param privateLinkServiceId string
param pendSubnetName string
param pendVnetName string
param dnsZoneName string
param groupIds array
param tags object

var dnslinkprefix = 'link-'


resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: '${subscription().id}/resourceGroups/rg-network-prod-westeu-001/providers/Microsoft.Network/virtualNetworks/${pendVnetName}/subnets/${pendSubnetName}'
    }
  }
}

resource privateEndpoints_Dnslink 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink_database_windows_net'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
  dependsOn: [
    privateDnsZone
  ]
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: dnsZoneName
  tags: tags
  location: 'global'
  properties: {
  }
}

resource privateDnsZonePrivatelink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZone
  tags: tags
  name: '${dnslinkprefix}${pendVnetName}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: '${subscription().id}/resourceGroups/rg-network-prod-westeu-001/providers/Microsoft.Network/virtualNetworks/${pendVnetName}'
    }
  }
}
