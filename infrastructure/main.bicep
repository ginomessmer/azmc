param location string = resourceGroup().location
param projectName string = 'azmc'

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

module rendering 'modules/renderer.bicep' = {
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

module logs 'modules/logs.bicep' = {
  name: 'logs'
  params: {
    location: location
    projectName: projectName
  }
}
