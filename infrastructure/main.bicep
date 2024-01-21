param location string = resourceGroup().location
param name string = 'azmc'

@description('Deploy the built-in Azure Portal dashboards.')
param deployDashboard bool = true

@description('Deploy the map renderer module (PREVIEW).')
param deployRenderer bool = false

// Server
module storageServer 'modules/storage-server.bicep' = {
  name: 'storageServer'
  params: {
    location: location
    projectName: name
  }
}

module server 'modules/server.bicep' = {
  name: 'server'
  dependsOn: [
    storageServer
    logs
  ]
  params: {
    location: location
    projectName: name
    serverStorageAccountName: storageServer.outputs.storageAccountServerName
    serverShareName: storageServer.outputs.storageAccountFileShareServerName
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

// Renderer
module storageRenderer 'modules/storage-map.bicep' = if(deployRenderer) {
  name: 'storageRenderer'
  params: {
    location: location
    projectName: name
  }
}

module renderer 'modules/renderer.bicep' = if(deployRenderer) {
  dependsOn: [
    storageRenderer
    server
    logs
  ]
  name: 'rendering'
  params: {
    location: location
    projectName: name
    renderingStorageAccountName: deployRenderer ? storageRenderer.outputs.storageAccountPublicMapName : ''
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
    managedEnvironmentName: deployRenderer ? renderer.outputs.containerEnvironmentName : ''
    serverContainerGroupName: server.outputs.containerGroupName
    storageAccountName: storageServer.outputs.storageAccountServerName
  }
}
