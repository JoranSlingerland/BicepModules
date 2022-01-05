//Parameters
param location string
param tags object

//Deployment
resource rsvVault 'Microsoft.RecoveryServices/vaults@2021-03-01' = {
  name: 'rsvVault'
  location: location
  tags: tags
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {}
}
