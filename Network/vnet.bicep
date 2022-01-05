//paramters
param location string
param vnetName string
param addresPrefix string
param subnets array
param nsgRules array
param tags object

//Deployment
resource nsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = [for subnet in subnets: {
  name: subnet.nsgName
  location: location
  tags: tags
  properties:{
  }
}]

// vnet rules
resource nsgRuleDeployment 'Microsoft.Network/networkSecurityGroups/securityRules@2020-11-01' = [for nsgRule in nsgRules:  {
  parent: nsg[nsgRule.parent]
  name: nsgRule.name
  properties: {
    access: nsgRule.access
    priority: nsgRule.priority
    direction: nsgRule.direction
    protocol: nsgRule.protocol
    sourceAddressPrefix: nsgRule.sourceAddressPrefix
    sourcePortRange: nsgRule.sourcePortRange
    destinationAddressPrefix: nsgRule.destinationAddressPrefix
    destinationPortRange: nsgRule.destinationPortRange
  }
}]

// Virtual network
resource vn 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addresPrefix
      ]
    }
    subnets: [for (subnet, i) in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.subnetprefix
        networkSecurityGroup: {
          id: nsg[i].id
        }
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    }]
  }
  dependsOn: [
    nsg
  ]
}

//outputs
output vnetID string = vn.id
