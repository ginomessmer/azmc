param location string = resourceGroup().location
param name string = 'azmc'

@description('Accept the Minecraft Server EULA.')
@allowed([true])
param acceptEula bool

@description('Deploy the built-in Azure Portal dashboards.')
param deployDashboard bool = true

@description('Deploy the map renderer module (PREVIEW).')
param deployRenderer bool = false

@description('Deploy the Discord bot module (PREVIEW). Make sure to supply the public key and token.')
param deployDiscordBot bool = false
@description('The public key for the Discord bot. Only required if deployDiscordBot is true.')
@secure()
param discordBotPublicKey string = ''
@description('The token for the Discord bot. Only required if deployDiscordBot is true.')
@secure()
param discordBotToken string = ''

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
    acceptEula: acceptEula
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

module discordBot 'modules/discord-bot.bicep' = if(deployDiscordBot && discordBotPublicKey != '' && discordBotToken != '') {
  dependsOn: [
    server
    logs
  ]
  name: 'discordBot'
  params: {
    location: location
    projectName: name

    workspaceName: logs.outputs.workspaceName
    minecraftContainerGroupName: server.outputs.containerGroupName
    discordBotPublicKey: discordBotPublicKey
    discordBotToken: discordBotToken

    containerLaunchManagerRoleId: roles.outputs.roleDefinitionContainerLaunchManagerId
  }
}

module roles 'modules/roles.bicep' = {
  name: 'roles'
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
