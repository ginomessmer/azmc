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
  params: {
    location: location
    projectName: projectName
    serverShareName: storage.outputs.serverFileShareName
    serverStorageAccountName: storage.outputs.storageAccountName
  }
}

module rendering 'modules/renderer.bicep' = {
  name: 'rendering'
  params: {
    location: location
    projectName: projectName
    renderingStorageAccountName: storage.outputs.storageAccountName
  }
}
