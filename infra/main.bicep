param location string = resourceGroup().location
param name string = 'azmc'

// Server
@description('Accept the Minecraft Server EULA.')
@allowed([true])
param acceptEula bool
@description('The memory size of the server in GB. Increase for large servers or maps.')
param serverMemorySize int = 3
@description('The type of server to deploy. Check the documentation for the list of supported server types: https://docker-minecraft-server.readthedocs.io/en/latest/types-and-platforms/. Commonly used types are SPIGOT, PAPER, and FORGE.')
param serverType string = 'PAPER'
@description('Enable Bedrock support for the server. This will allow Bedrock clients to connect to the server.')
param isBedrockSupportEnabled bool = false

// Dashboard
@description('Deploy the built-in Azure Portal dashboards.')
param deployDashboard bool = true

// Web map
@description('Deploy the map renderer module.')
param deployRenderer bool = false
@description('The schedule for rendering the map. The map will be rendered at the specified interval. The supported values are weekly, daily, hourly, and every5Minutes.')
@allowed([
  'weekly'
  'daily'
  'hourly'
  'every5Minutes'
])
param rendererSchedule string = 'weekly'
@description('The host name for the web map.')
param mapHostName string = ''
@description('(optional) The Azure AD client ID for the web map. Only required if deployRenderer is true.')
@secure()
param webMapAuthClientId string?
@description('(optional) The Azure AD client secret for the web map. Only required if deployRenderer is true.')
@secure()
param webMapAuthClientSecret string?
@description('(optional) The list of allowed identities for the web map. Only required if deployRenderer is true.')
param webMapIdentitiesAllowlist string[] = []

// Discord bot
@description('Deploy the Discord bot module. Make sure to supply the public key and token.')
param deployDiscordBot bool = false
@description('The public key for the Discord bot. Only required if deployDiscordBot is true.')
@secure()
param discordBotPublicKey string = ''
@description('The token for the Discord bot. Only required if deployDiscordBot is true.')
@secure()
param discordBotToken string = ''

// Resources
@description('Deploy the services required to host resources, such as resource packs.')
param deployResources bool = true
@description('The file name of the resource pack to deploy. Make sure to upload the resource pack to the storage account using the same name. Only required if deployResources is true.')
param resourcePackName string = ''

@description('Determines if the resource pack is hosted externally. If true, the resource pack will be linked to the Minecraft server. If false, AZMC assumes that the resource pack is hosted on the deployed resources storage account.')
var isResourcePackExternal = startsWith(resourcePackName, 'https://')

// Auto shutdown
@description('Automatically shut down the server at midnight.')
param deployAutoShutdown bool = true


// Docker Hub settings
@description('The Docker Hub username.')
param dockerHubUsername string = ''
@description('The Docker Hub password.')
@secure()
param dockerHubPassword string = ''

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
    serverType: serverType
    projectName: name
    serverStorageAccountName: storageServer.outputs.storageAccountServerName
    serverShareName: storageServer.outputs.storageAccountFileShareServerName
    workspaceName: logs.outputs.workspaceName
    memorySize: serverMemorySize
    isBedrockSupportEnabled: isBedrockSupportEnabled
    resourcePackUrl: (deployResources && resourcePackName != '') || isResourcePackExternal
      ? isResourcePackExternal
        ? resourcePackName : '${resources.outputs.storageAccountResourcePackEndpoint}/${resourcePackName}'
      : ''
    dockerHubUsername: dockerHubUsername
    dockerHubPassword: dockerHubPassword
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
    schedule: rendererSchedule
    containerEnvironmentName: containerEnvironment.outputs.containerEnvironmentName
    mapRendererStorageAccountName: storageRenderer.outputs.storageAccountPublicMapName
    webMapHostName: mapHostName
    authClientSecret: webMapAuthClientSecret
  }
}

module rendererAuth 'modules/auth.bicep' = if(!empty(webMapAuthClientId) && deployRenderer) {
  name: 'rendererAuth'
  params: {
    containerAppName: renderer.outputs.webMapContainerAppName
    clientId: webMapAuthClientId!
    allowedIdentities: webMapIdentitiesAllowlist
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

// Resources
module resources 'modules/storage-resources.bicep' = if(deployResources) {
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
    webMapContainerAppId: deployRenderer ? renderer.outputs.webMapContainerAppId : ''
    minecraftServerContainerInstanceName: server.outputs.containerGroupName
    serverStorageAccountId: storageServer.outputs.storageAccountId
  }
}

output minecraftServerContainerGroupName string = server.outputs.containerGroupName
output minecraftServerFqdn string = server.outputs.containerGroupFqdn
output discordInteractionEndpoint string? = deployDiscordBot ? format('https://{0}/interactions', discordBot.outputs.containerAppUrl) : null

output webMapFqdn string = deployRenderer ? renderer.outputs.webMapFqdn : ''
