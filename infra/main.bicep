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

@description('Automatically shut down the server at midnight.')
param deployAutoShutdown bool = true

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

// Container environment
module containerEnvironment 'modules/container-env.bicep' = {
  name: 'containerEnvironment'
  params: {
    location: location
    projectName: name
    workspaceName: logs.outputs.workspaceName
  }
}

// Operational
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
    containerEnvironmentId: containerEnvironment.outputs.containerEnvironmentId
    deployRendererJob: deployRenderer
  }
}

// Discord bot
module discordBot 'modules/discord-bot.bicep' = if(deployDiscordBot && discordBotPublicKey != '' && discordBotToken != '') {
  dependsOn: [
    server
    logs
  ]
  name: 'discordBot'
  params: {
    location: location
    projectName: name

    containerEnvironmentId: containerEnvironment.outputs.containerEnvironmentId
    minecraftContainerGroupName: server.outputs.containerGroupName
    discordBotPublicKey: discordBotPublicKey
    discordBotToken: discordBotToken

    containerLaunchManagerRoleId: roles.outputs.roleDefinitionContainerLaunchManagerId
  }
}

// Auto shutdown
module autoShutdown 'modules/auto-shutdown.bicep' = if (deployAutoShutdown) {
  name: 'autoShutdown'
  params: {
    location: location
    projectName: name
    
    containerGroupName: server.outputs.containerGroupName
    roleDefinitionId: roles.outputs.roleDefinitionContainerLaunchManagerId
  }
}

// Access management
module roles 'modules/roles.bicep' = {
  name: 'roles'
}

// Dashboard
module dashboards 'dashboards/default.bicep' = if(deployDashboard) {
  name: 'dashboards'
  params: {
    location: location
    projectName: name
    
    discordBotContainerAppId: deployDiscordBot ? discordBot.outputs.containerAppId : ''
    minecraftServerContainerInstanceName: server.outputs.containerGroupName
    serverStorageAccountId: storageServer.outputs.storageAccountId
  }
}

output minecraftServerEndpoint string = server.outputs.containerGroupFqdn
output discordInteractionEndpoint string? = deployDiscordBot ? format('https://{0}/interactions', discordBot.outputs.containerAppUrl)   : null
