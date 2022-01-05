//Parameters
param location string
param vmConfigurations array
param pipVmConfigurations array 
@secure()
param localAdminPassword string
param localAdminUsername string
@secure()
param virtualNetworkId string
param tags object

//Variables
var storage = {
  type: 'Premium_LRS'
}
var virtualmachineosdisk = {
  cacheOption: 'ReadWrite'
  createOption: 'FromImage'
  diskName: 'OS'
}
var vmTimeZone = 'W. Europe Standard Time'
var networkAdapterIPConfigName = 'ipconfig'
var networkAdapterNamePostFix = '-nic'
var networkAdapterIPAllocationMethod = 'Dynamic'
var pipNamePostFix = '-pip'

//modules
module pip '../network/pip.bicep' = [for vmConfig in pipVmConfigurations: {
  name: '${vmConfig.resourceName}${pipNamePostFix}'
  scope: resourceGroup()
  params: {
    tags: tags
    location: location
    name: '${vmConfig.resourceName}${pipNamePostFix}'
  }
}]


//Deployment
resource noPipNic 'Microsoft.Network/networkInterfaces@2020-06-01' = [for vmConfig in vmConfigurations: {
  name: '${vmConfig.resourceName}${networkAdapterNamePostFix}'
  location: location
  tags: tags
  properties: {
    enableAcceleratedNetworking: true
    ipConfigurations: [
      {
        name: networkAdapterIPConfigName
        properties: {
          privateIPAllocationMethod: networkAdapterIPAllocationMethod
          subnet: {
            id: '${virtualNetworkId}/subnets/${vmConfig.subnetName}'
          }
        }
      }
    ]
  }
}]

resource PipNic 'Microsoft.Network/networkInterfaces@2020-06-01' = [for (vmConfig, i) in pipVmConfigurations: {
  name: '${vmConfig.resourceName}${networkAdapterNamePostFix}'
  location: location
  tags: tags
  properties: {
    enableAcceleratedNetworking: true
    ipConfigurations: [
      {
        name: networkAdapterIPConfigName
        properties: {
          privateIPAllocationMethod: networkAdapterIPAllocationMethod
          subnet: {
            id: '${virtualNetworkId}/subnets/${vmConfig.subnetName}'
          }
          publicIPAddress: {
            id: pip[i].outputs.pipId
          }
        }
      }
    ]
  }
  dependsOn: [
    pip[i]
  ]
}]

resource noPipVm 'Microsoft.Compute/virtualMachines@2020-06-01' = [for (vmConfig, i) in vmConfigurations: {
  name: vmConfig.resourceName
  location: location
  tags: tags
  properties: {

    hardwareProfile: {
      vmSize: vmConfig.virtualMachineSize
    }
    osProfile: {
      computerName: vmConfig.hostName
      adminUsername: localAdminUsername
      adminPassword: localAdminPassword
      windowsConfiguration: {
        timeZone: vmTimeZone
      }
    }
    storageProfile: {
      osDisk: {
        name: '${vmConfig.resourceName}-${virtualmachineosdisk.diskName}'
        managedDisk: {
          storageAccountType: storage.type
        }
        osType: 'Windows'
        caching: virtualmachineosdisk.cacheOption
        createOption: virtualmachineosdisk.createOption
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-datacenter-gensecond'
        version: 'latest'
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: '${resourceGroup().id}/providers/Microsoft.Network/networkInterfaces/${vmConfig.resourceName}${networkAdapterNamePostFix}'
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn:[
    noPipNic[i]
  ]
}]

resource pipVm 'Microsoft.Compute/virtualMachines@2020-06-01' = [for (vmConfig, i) in pipVmConfigurations: {
  name: vmConfig.resourceName
  location: location
  tags: tags
  properties: {

    hardwareProfile: {
      vmSize: vmConfig.virtualMachineSize
    }
    osProfile: {
      computerName: vmConfig.hostName
      adminUsername: localAdminUsername
      adminPassword: localAdminPassword
      windowsConfiguration: {
        timeZone: vmTimeZone
      }
    }
    storageProfile: {
      osDisk: {
        name: '${vmConfig.resourceName}-${virtualmachineosdisk.diskName}'
        managedDisk: {
          storageAccountType: storage.type
        }
        osType: 'Windows'
        caching: virtualmachineosdisk.cacheOption
        createOption: virtualmachineosdisk.createOption
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-datacenter-gensecond'
        version: 'latest'
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: '${resourceGroup().id}/providers/Microsoft.Network/networkInterfaces/${vmConfig.resourceName}${networkAdapterNamePostFix}'
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn:[
    PipNic[i]
  ]
}]

resource PipWindowsVMGuestConfigExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = [for (vmConfig, i) in pipVmConfigurations: {
  name: '${vmConfig.resourceName}/AzurePolicyforWindows'
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'ConfigurationforWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {}
    protectedSettings: {}
  }
  dependsOn: [
    pipVm[i]
  ]
}]

resource noPipWindowsVMGuestConfigExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = [for (vmConfig, i) in vmConfigurations: {
  name: '${vmConfig.resourceName}/AzurePolicyforWindows'
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'ConfigurationforWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {}
    protectedSettings: {}
  }
  dependsOn: [
    noPipVm[i]
  ]
}]
