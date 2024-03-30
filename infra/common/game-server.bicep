param location string
param name string

// Server
module storageServer '../modules/storage-server.bicep' = {
  name: 'storageServer'
  params: {
    location: location
    projectName: name
  }
}

module server '../modules/server.bicep' = {
  name: 'server'
  dependsOn: [
    storageServer
    logs
  ]
  params: {
    location: location
    acceptEula: acceptEula
    serverType: serverType
    projectName: name
    serverStorageAccountName: storageServer.outputs.storageAccountServerName
    serverShareName: storageServer.outputs.storageAccountFileShareServerName
    workspaceName: logs.outputs.workspaceName
    memorySize: serverMemorySize
    resourcePackUrl: (deployResources && resourcePackName != '') || isResourcePackExternal
      ? isResourcePackExternal
        ? resourcePackName : '${resources.outputs.storageAccountResourcePackEndpoint}/${resourcePackName}'
      : ''
  }
}
