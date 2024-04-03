param location string
param projectName string

// Volume settings
param serverShareName string = 'server'
param serverStorageAccountName string

// Minecraft settings
// Most settings can be found at https://docker-minecraft-server.readthedocs.io/
@description('The Minecraft version of the server.')
param minecraftVersion string = 'LATEST'

@description('The type of the server.')
param serverType string = 'SPIGOT'

@description('Recommended size: min. 3 GB RAM')
param memorySize int = 3

@description('Recommended size: min. 2 CPU cores')
param cpuCores int = 2

@description('Enable autostop of the server when no players are online.')
param isAutostopEnabled string = 'TRUE'

@description('Accept the Minecraft EULA.')
param acceptEula bool

@description('The URL of the Minecraft resource pack.')
param resourcePackUrl string

// Log Analytics settings
param workspaceName string

var serverMountPath = '/data'

module gameServer 'modules/server.bicep' = {
  name: 'gameServer'
  params: {
    location: location
    containers: [ minecraftContainer ]
    gamePort: 25565
    projectName: projectName
    volumes: [ minecraftContainerVolume ]
    workspaceName: workspaceName
  }
}

// Container settings
var minecraftContainer = {
  name: 'server'
  properties: {
    image: 'itzg/minecraft-server'
    ports: [
      {
        port: 25565
        protocol: 'TCP'
      }
    ]
    environmentVariables: [
      {
        name: 'EULA'
        value: string(acceptEula)
      }
      {
        name: 'TYPE'
        value: serverType
      }
      {
        name: 'VERSION'
        value: minecraftVersion
      }
      {
        name: 'ENABLE_AUTOSTOP'
        value: isAutostopEnabled
      }
      {
        name: 'MEMORY'
        value: '${memorySize}G'
      }
      {
        name: 'RESOURCE_PACK'
        value: resourcePackUrl != '' ? resourcePackUrl : ''
      }
    ]
    volumeMounts: [
      {
        name: 'server'
        mountPath: serverMountPath
        readOnly: false
      }
    ]
    resources: {
      requests: {
        cpu: string(cpuCores)
        memoryInGB: memorySize + 1
      }
    }
  }
}

var minecraftContainerVolume = {
  name: 'server'
  azureFile: {
    readOnly: false
    shareName: serverShareName
    storageAccountName: serverStorageAccountName
    storageAccountKey: storageAccount.listKeys().keys[0].value
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: serverStorageAccountName
}

output containerGroupName string = gameServer.outputs.containerGroupName
output containerGroupFqdn string = gameServer.outputs.containerGroupFqdn
