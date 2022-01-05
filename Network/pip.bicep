param name string
param location string
param tags object
param zones array = [
  '1'
  '2'
  '3'
]
@allowed([
  'Basic'
  'Standard'
])
param sku string = 'Standard'
@allowed([
  'Dynamic'
  'Static'
])
param publicIPAllocationMethod string = 'Static'
param idleTimeoutInMinutes int = 4
param publicIpAddressVersion string = 'IPv4'

@allowed([
  'Regional'
  'Global'
])
param tier string = 'Regional'

resource pip 'Microsoft.Network/publicIPAddresses@2020-08-01' = {
  zones: zones
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
    tier: tier
  }
  properties: {
    publicIPAllocationMethod: publicIPAllocationMethod
    idleTimeoutInMinutes: idleTimeoutInMinutes
    publicIPAddressVersion: publicIpAddressVersion
    ipTags: []
  }
}

output pipId string = pip.id
