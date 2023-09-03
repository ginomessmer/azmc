param location string = resourceGroup().location
param projectName string = 'azmc'

@description('Deploy the built-in Azure Portal dashboards.')
param deployDashboard bool = true

@description('Deploy the map renderer module.')
param deployRenderer bool = true

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    projectName: projectName
  }
}

module server 'modules/server.bicep' = {
  name: 'server'
  dependsOn: [
    storage
    logs
  ]
  params: {
    location: location
    projectName: projectName
    serverShareName: storage.outputs.serverFileShareName
    serverStorageAccountName: storage.outputs.storageAccountName
    workspaceName: logs.outputs.workspaceName
  }
}

module logs 'modules/logs.bicep' = {
  name: 'logs'
  params: {
    location: location
    projectName: projectName
  }
}

module renderer 'modules/renderer.bicep' = if(deployRenderer) {
  dependsOn: [
    storage
    server
    logs
  ]
  name: 'rendering'
  params: {
    location: location
    projectName: projectName
    renderingStorageAccountName: storage.outputs.storageAccountName
    workspaceName: logs.outputs.workspaceName
  }
}

module dashboards 'dashboards/default.bicep' = if(deployDashboard) {
  name: 'dashboards'
  params: {
    location: location
    projectName: projectName

    logAnalyticsWorkspaceName: logs.outputs.workspaceName
    managedEnvironmentName: renderer.outputs.containerEnvironmentName
    serverContainerGroupName: server.outputs.containerGroupName
    storageAccountName: storage.outputs.storageAccountName
  }
}
