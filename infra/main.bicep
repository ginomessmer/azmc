param location string = resourceGroup().location
param name string = 'azmc'

// Server
@description('Accept the Minecraft Server EULA.')
@allowed([true])
param acceptEula bool

@description('The memory size of the server in GB. Increase for large servers or maps.')
param serverMemorySize int = 3

// Dashboard
@description('Deploy the built-in Azure Portal dashboards.')
param deployDashboard bool = true

// Web map
@description('Deploy the map renderer module.')
param deployRenderer bool = false
@description('Use the CDN to serve the rendered map. If false, the rendered map will be served from the Container App.')
param useCdn bool = true
@description('The host name for the web map.')
param mapHostName string = ''

// Discord bot
@description('Deploy the Discord bot module. Make sure to supply the public key and token.')
param deployDiscordBot bool = false
@description('The public key for the Discord bot. Only required if deployDiscordBot is true.')
@secure()
param discordBotPublicKey string = ''
@description('The token for the Discord bot. Only required if deployDiscordBot is true.')
@secure()
param discordBotToken string = ''

// Auto shutdown
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
    memorySize: serverMemorySize
  }
}

// Container environment
module containerEnvironment 'modules/container-env.bicep' = {
  name: 'containerEnvironment'
  params: {
    location: location
    projectName: name
    workspaceName: logs.outputs.workspaceName
    minecraftServerStorageAccountName: storageServer.outputs.storageAccountServerName
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
    containerEnvironmentName: containerEnvironment.outputs.containerEnvironmentName
    mapRendererStorageAccountName: storageRenderer.outputs.storageAccountPublicMapName
    useCdn: useCdn
    webMapHostName: mapHostName
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

output minecraftServerContainerGroupName string = server.outputs.containerGroupName
output minecraftServerFqdn string = server.outputs.containerGroupFqdn
output discordInteractionEndpoint string? = deployDiscordBot ? format('https://{0}/interactions', discordBot.outputs.containerAppUrl)   : null

output webMapFqdn string = deployRenderer ? renderer.outputs.webMapFqdn : ''
