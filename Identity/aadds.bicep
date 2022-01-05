//Paramaters
param AADDSSku string
param domainConfigurationType string
param aaddsResourceName string
param domainName string
param filteredSync string
param location string
param virtualNetworkId string
param subnetName string
param tlsV1 string
param ntlmV1 string
param syncNtlmPasswords string
param syncOnPremPasswords string
param kerberosRc4Encryption string
param kerberosArmoring string
param tags object

//variables
var vnetId = virtualNetworkId
var subnetRef = '${vnetId}/subnets/${subnetName}'

//Deployment
resource domainName_resource 'Microsoft.AAD/DomainServices@2021-03-01' = {
  name: aaddsResourceName
  location: location
  tags: tags
  properties: {
    domainName: domainName
    filteredSync: filteredSync
    domainConfigurationType: domainConfigurationType
    notificationSettings: {
      notifyDcAdmins: 'Enabled'
      notifyGlobalAdmins: 'Enabled'
    }
    replicaSets: [
      {
        subnetId: subnetRef
        location: location
      }
    ]
    domainSecuritySettings: {
      tlsV1: tlsV1
      ntlmV1: ntlmV1
      syncNtlmPasswords: syncNtlmPasswords
      syncOnPremPasswords: syncOnPremPasswords
      kerberosRc4Encryption: kerberosRc4Encryption
      kerberosArmoring: kerberosArmoring
    }
    sku: AADDSSku
  }
}
