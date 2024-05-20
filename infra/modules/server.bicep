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

@description('Enable server support for Bedrock Edition players using Geyser. Does not contain Floodgate. For more information, see https://geysermc.org/.')
param isBedrockSupportEnabled bool = true

@description('Accept the Minecraft EULA.')
param acceptEula bool

@description('The URL of the Minecraft resource pack.')
param resourcePackUrl string

// Log Analytics settings
param workspaceName string

var serverMountPath = '/data'

var containerGroupName = 'ci-${projectName}-server'

// Container settings
var minecraftContainer = {
  name: 'server'
  properties: {
    image: 'itzg/minecraft-server'
    ports: [
      {
        // Minecraft
        port: 25565
        protocol: 'TCP'
      }
      isBedrockSupportEnabled ? {
        // Geyser
        port: 19132
        protocol: 'UDP'
      } : { }
    ]
    environmentVariables: [
      {
        name: 'EULA'
        value: acceptEula
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
      isBedrockSupportEnabled ? {
        name: 'PLUGINS'
        value: [
          'https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot'
        ]
      } : { }
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
        cpu: cpuCores
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

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: containerGroupName
  location: location
  properties: {
    osType: 'Linux'
    containers: [
      minecraftContainer
    ]
    volumes: [
      minecraftContainerVolume
    ]
    restartPolicy: 'OnFailure'
    diagnostics: {
      logAnalytics: {
        workspaceId: workspace.properties.customerId
        workspaceKey: workspace.listKeys().primarySharedKey
      }
    }
    ipAddress: {
      type: 'Public'
      dnsNameLabel: projectName
      ports: [
        {
          protocol: 'TCP'
          port: 25565
        }
        isBedrockSupportEnabled ? {
          protocol: 'UDP'
          port: 19132
        } : { }
      ]
    }
  }
}

output containerGroupFqdn string = containerGroup.properties.ipAddress.fqdn
output containerGroupId string = containerGroup.id
output containerGroupName string = containerGroup.name
