param location string = resourceGroup().location
param name string = 'azmc'

@description('The game to deploy. Supported games are Minecraft and Counter-Strike 2.0.')
param game 'minecraft' | 'cs2'

// Game config
param minecraftConfig {
  // Server
  @description('Accept the Minecraft Server EULA.')
  acceptEula: bool
  @description('The memory size of the server in GB. Increase for large servers or maps.')
  serverMemorySize: int
  @description('The type of server to deploy. Check the documentation for the list of supported server types: https://docker-minecraft-server.readthedocs.io/en/latest/types-and-platforms/. Commonly used types are SPIGOT, PAPER, and FORGE.')
  serverType: string

  // Web map
  @description('Deploy the map renderer module.')
  deployRenderer: bool
  @description('Use the CDN to serve the rendered map. If false, the rendered map will be served from the Container App.')
  useCdn: bool
  @description('The host name for the web map.')
  mapHostName: string

  // Resources
  @description('Deploy the services required to host resources, such as resource packs.')
  deployResources: bool
  @description('The file name of the resource pack to deploy. Make sure to upload the resource pack to the storage account using the same name. Only required if deployResources is true.')
  resourcePackName: string
} = {
  acceptEula: false
  deployRenderer: false
  deployResources: true
  mapHostName: ''
  resourcePackName: ''
  serverMemorySize: 3
  serverType: 'PAPER'
  useCdn: true
}

param cs2Config {
  @description('The GSLT token for the Counter-Strike 2.0 server.')
  gslt: string
  @description('The Steam Web API key for the Counter-Strike 2.0 server.')
  steamWebApiKey: string
} = {
  gslt: ''
  steamWebApiKey: ''
}

@description('Determines if the resource pack is hosted externally. If true, the resource pack will be linked to the Minecraft server. If false, AZMC assumes that the resource pack is hosted on the deployed resources storage account.')
var isResourcePackExternal = startsWith(minecraftConfig.resourcePackName, 'https://')

// Dashboard
@description('Deploy the built-in Azure Portal dashboards.')
param deployDashboard bool = true

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

module minecraftServer 'minecraft.bicep' = if (game == 'minecraft') {
  name: 'server'
  dependsOn: [
    storageServer
    logs
  ]
  params: {
    location: location
    acceptEula: minecraftConfig.acceptEula
    serverType: minecraftConfig.serverType
    projectName: name
    serverStorageAccountName: storageServer.outputs.storageAccountServerName
    serverShareName: storageServer.outputs.storageAccountFileShareServerName
    workspaceName: logs.outputs.workspaceName
    memorySize: minecraftConfig.serverMemorySize
    resourcePackUrl: (minecraftConfig.deployResources && minecraftConfig.resourcePackName != '') || isResourcePackExternal
      ? isResourcePackExternal
        ? minecraftConfig.resourcePackName : '${resources.outputs.storageAccountResourcePackEndpoint}/${minecraftConfig.resourcePackName}'
      : ''
  }
}

 module cs2Server 'cs2.bicep' = if (game == 'cs2') {
  name: 'cs2Server'
  dependsOn: [
    storageServer
    logs
  ]
  params: {
    location: location
    name: name
    gslt: cs2Config.gslt
    steamWebApiKey: cs2Config.steamWebApiKey
    serverShareName: storageServer.outputs.storageAccountFileShareServerName
    serverStorageAccountName: storageServer.outputs.storageAccountServerName
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
module storageRenderer 'modules/storage-map.bicep' = if(minecraftConfig.deployRenderer) {
  name: 'storageRenderer'
  params: {
    location: location
    projectName: name
  }
}

module renderer 'modules/renderer.bicep' = if(minecraftConfig.deployRenderer) {
  dependsOn: [
    storageRenderer
    minecraftServer
    logs
  ]
  name: 'rendering'
  params: {
    location: location
    projectName: name
    containerEnvironmentName: containerEnvironment.outputs.containerEnvironmentName
    mapRendererStorageAccountName: storageRenderer.outputs.storageAccountPublicMapName
    useCdn: minecraftConfig.useCdn
    webMapHostName: minecraftConfig.mapHostName
  }
}

// Discord bot
module discordBot 'modules/discord-bot.bicep' = if(deployDiscordBot && discordBotPublicKey != '' && discordBotToken != '') {
  dependsOn: [
    containerEnvironment
    logs
  ]
  name: 'discordBot'
  params: {
    location: location
    projectName: name

    containerEnvironmentId: containerEnvironment.outputs.containerEnvironmentId
    minecraftContainerGroupName: minecraftServer.outputs.containerGroupName
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
    
    containerGroupName: minecraftServer.outputs.containerGroupName
    roleDefinitionId: roles.outputs.roleDefinitionContainerLaunchManagerId
  }
}

// Resources
module resources 'modules/storage-resources.bicep' = if(minecraftConfig.deployResources) {
  name: 'resources'
  params: {
    location: location
    projectName: name
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
    minecraftServerContainerInstanceName: minecraftServer.outputs.containerGroupName
    serverStorageAccountId: storageServer.outputs.storageAccountId
  }
}

output minecraftServerContainerGroupName string = minecraftServer.outputs.containerGroupName
output minecraftServerFqdn string = minecraftServer.outputs.containerGroupFqdn
output discordInteractionEndpoint string? = deployDiscordBot ? format('https://{0}/interactions', discordBot.outputs.containerAppUrl) : null

output webMapFqdn string = minecraftConfig.deployRenderer ? renderer.outputs.webMapFqdn : ''
