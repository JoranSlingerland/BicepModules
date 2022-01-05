//Parameters
param location string
param adDomainName string
param assetLocation string = 'https://raw.githubusercontent.com/fberson/wvd/master/'
param availabilitySetName string
param domainJoinUPN string
param existingSharedImageGalleryName string
param existingSharedImageGalleryDefinitionName string
param existingSharedImageGalleryVersionName string = 'latest'
param existingSharedImageGalleryResourceGroup string
param existingSubnetName string
param resouceNamePrefixWVD string
param hostNamePrefixWVD string
param numberOfInstancesWVD int
param sequenceStartNumberWVDHost int
param virtualMachineSizeWVD string
@secure()
param localAdminPassword string
param localAdminUsername string
@secure()
param domainJoinPassword string
param registrationKey string
param virtualNetworkId string
param ouPath string
param tags object

//Variables
var domainJoinOptions = 3
var networkSubnetId = '${virtualNetworkId}/subnets/${existingSubnetName}'
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
var imageResourceId = resourceId(existingSharedImageGalleryResourceGroup, 'Microsoft.Compute/galleries/images/versions', existingSharedImageGalleryName, existingSharedImageGalleryDefinitionName, existingSharedImageGalleryVersionName)
var configurationScriptWVD = 'Add-WVDHostToHostpoolSpringV2.ps1'

//Deployment
resource avset 'Microsoft.Compute/availabilitySets@2020-06-01' = {
  name:availabilitySetName
  location: location
  tags: tags
  properties: {
    platformUpdateDomainCount: 2
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2020-06-01' = [for i in range(0, numberOfInstancesWVD): {
  name: '${resouceNamePrefixWVD}-${(i+sequenceStartNumberWVDHost)}${networkAdapterNamePostFix}'
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
            id: networkSubnetId
          }
        }
      }
    ]
  }
}]

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = [for i in range(0, numberOfInstancesWVD): {
  name: '${resouceNamePrefixWVD}-${(i+sequenceStartNumberWVDHost)}'
  location: location
  tags: tags
  properties: {
    licenseType: 'Windows_Client'
    hardwareProfile: {
      vmSize: virtualMachineSizeWVD
    }
    availabilitySet: {
      id: avset.id
    }
    osProfile: {
      computerName: '${hostNamePrefixWVD}-${(i+sequenceStartNumberWVDHost)}'
      adminUsername: localAdminUsername
      adminPassword: localAdminPassword
      windowsConfiguration: {
        timeZone: vmTimeZone
      }
    }
    storageProfile: {
      osDisk: {
        name: '${resouceNamePrefixWVD}-${(i+sequenceStartNumberWVDHost)}-${virtualmachineosdisk.diskName}'
        managedDisk: {
          storageAccountType: storage.type
        }
        osType: 'Windows'
        caching: virtualmachineosdisk.cacheOption
        createOption: virtualmachineosdisk.createOption
      }
      imageReference: {
        id: imageResourceId
      }
      // imageReference: {
      //   publisher: 'microsoftwindowsdesktop'
      //   offer: 'office-365'
      //   sku: '20h2-evd-o365pp-g2'
      //   version: 'latest'
      // }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic[i].id
        }
      ]
    }
  }
}]

resource wvd 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = [for i in range(0, numberOfInstancesWVD): {
  name: '${vm[i].name}/wvd'
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.8'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${assetLocation}${configurationScriptWVD}'
      ]
    }
    protectedSettings: {
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File ${configurationScriptWVD} ${registrationKey}'
    }
  }
  dependsOn: [
    domainjoin[i]
  ]
}]

resource domainjoin 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = [for i in range(0, numberOfInstancesWVD): {
  name: '${vm[i].name}/domainjoin'
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: adDomainName
      User: domainJoinUPN
      Restart: true
      Options: domainJoinOptions
      OUpath: ouPath
    }
    protectedSettings: {
      Password: domainJoinPassword
    }
  }
  dependsOn: [
    vm[i]
  ]
}]
