param location string = resourceGroup().location
param name string = 'azmc'

@description('Deploy the built-in Azure Portal dashboards.')
param deployDashboard bool = true

@description('Deploy the map renderer module (PREVIEW).')
param deployRenderer bool = false

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    projectName: name
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
    projectName: name
    serverShareName: storage.outputs.serverFileShareName
    serverStorageAccountName: storage.outputs.storageAccountName
    workspaceName: logs.outputs.workspaceName
  }
}

module logs 'modules/logs.bicep' = {
  name: 'logs'
  params: {
    location: location
    projectName: name
  }
}

module renderer 'modules/renderer.bicep' = {
  dependsOn: [
    storage
    server
    logs
  ]
  name: 'rendering'
  params: {
    location: location
    projectName: name
    renderingStorageAccountName: storage.outputs.storageAccountName
    workspaceName: logs.outputs.workspaceName
    deployRendererJob: deployRenderer
  }
}

module dashboards 'dashboards/default.bicep' = if(deployDashboard) {
  name: 'dashboards'
  params: {
    location: location
    projectName: name

    logAnalyticsWorkspaceName: logs.outputs.workspaceName
    managedEnvironmentName: renderer.outputs.containerEnvironmentName
    serverContainerGroupName: server.outputs.containerGroupName
    storageAccountName: storage.outputs.storageAccountName
  }
}
