//Paramters
param automationAccountName string
param location string
param tags object

//Deployment
resource automationAccount 'Microsoft.Automation/automationAccounts@2020-01-13-preview' = {
  name: automationAccountName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'Basic'
    }
  }
  dependsOn: []
}
