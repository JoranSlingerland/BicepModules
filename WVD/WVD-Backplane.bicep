//Parameters
param location string
param workspaceName string
param workspaceFriendlyName string
param hostpoolName string
param hostpoolFriendlyName string
//param preferredAppGroupType string for some reason this erros out, blanking it fixes the issue
param hostPoolType string
param loadbalancertype string
param wvdConfig array
param maxSessionLimit int
param tags object

//Deployment
resource hp 'Microsoft.DesktopVirtualization/hostpools@2019-12-10-preview' = {
    name: hostpoolName
    location: location
    tags: tags
    properties: {
      friendlyName: hostpoolFriendlyName
      hostPoolType : hostPoolType
      loadBalancerType : loadbalancertype
      //preferredAppGroupType: preferredAppGroupType for some reason this erros out, blanking it fixes the issue
      maxSessionLimit: maxSessionLimit
    }
  }

resource ag 'Microsoft.DesktopVirtualization/applicationgroups@2019-12-10-preview' = [for config in wvdConfig: {
name: config.appgroupName
location: location
tags: tags
properties: {
    friendlyName: config.appgroupFriendlyName
    applicationGroupType: config.appgroupType
    hostPoolArmPath: hp.id
  }
}]

resource ws 'Microsoft.DesktopVirtualization/workspaces@2019-12-10-preview' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
      friendlyName: workspaceFriendlyName
      applicationGroupReferences: [for (config, i) in wvdConfig: ag[i].id]
  }
}

//configur logging for AVD
resource avdLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'AVDLogs'
  scope: ws
  properties: {
    workspaceId: 'id'
    logs: [
      {
        category: 'autditevent'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: true
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
