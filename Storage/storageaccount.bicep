//Parameters
param location string
@minLength(3)
@maxLength(24)
param storageAccountName string
param storagePrivateEndpointName string
param shareQuota int
param storagePendSubnetName string
param storagePendVnetName string
param tags object

//Variables
var accountType = 'Premium_ZRS'
var kind = 'FileStorage'
var minimumTlsVersion = 'TLS1_2'
var supportsHttpsTrafficOnly = true
var allowBlobPublicAccess = false
var allowSharedKeyAccess = true
var networkAclsBypass = 'AzureServices'
var networkAclsDefaultAction = 'Deny'
var largeFileSharesState = 'Enabled'
var fileshareFolderName = 'profilecontainers'
var filesharelocation = '${storageAccount.name}/default/${fileshareFolderName}'
var dnsZoneName = 'privatelink.file.core.windows.net'
var groupIds = [
  'file'
]

//Deployment
resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  tags: tags
  properties: {
    minimumTlsVersion: minimumTlsVersion
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    allowBlobPublicAccess: allowBlobPublicAccess
    allowSharedKeyAccess: allowSharedKeyAccess
    networkAcls: {
      bypass: networkAclsBypass
      defaultAction: networkAclsDefaultAction
      ipRules: [
      ]
    }
    largeFileSharesState: largeFileSharesState
  }
  sku: {
    name: accountType
  }
  kind: kind
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-04-01' = {
  name :  filesharelocation
  properties: {
    accessTier: 'Premium'
    shareQuota: shareQuota
    enabledProtocols: 'SMB'
  }
  dependsOn: [
    storageAccount
  ]
}

module privateEndpoint '../network/privateendpoint.bicep' = {
  name: 'privateEndpoint'
  scope: resourceGroup()
  params: {
    tags: tags
    location: location
    dnsZoneName: dnsZoneName
    pendSubnetName: storagePendSubnetName
    pendVnetName: storagePendVnetName
    privateEndpointName: storagePrivateEndpointName
    privateLinkServiceId: storageAccount.id
    groupIds: groupIds
  }
  dependsOn: [
    storageAccount
  ]
}
