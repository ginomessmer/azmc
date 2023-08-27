param location string = resourceGroup().location

@description('Display label of the container resources. These labels are visible in some FQDN. Min. 4 letters, max. 24 letters')
param name string = 'azmc'

@description('The Minecraft version of the server.')
param minecraftVersion string = 'LATEST'

@description('Recommended size: min. 3 GB RAM')
param memorySize int = 3

@description('Recommended size: min. 2 CPU cores')
param cpuCores int = 2

@description('')
param overviewerEnabled bool

@allowed([
  'TRUE'
  'FALSE'
])
param isAutostopEnabled string = 'TRUE'

var serverShareName = 'server'
var overviewerShareName = 'overviewer'
var serverMountPath = '/data'
var serverType = 'SPIGOT'

var storageAccountName = take(replace(replace('${name}${uniqueString(name)}', '-', ''), '_', ''), 24)
var serverShareResourceName = '${storage.name}/default/${serverShareName}'
var overviewerShareResourceName = '${storage.name}/default/${overviewerShareName}'
var containerGroupName = 'cg-${name}'
var workspaceName = 'ws-${name}'

// Container settings

var minecraftContainer = {
  name: 'server'
  properties: {
    image: 'itzg/minecraft-server'
    ports: [
      {
        port: 25565
      }
    ]
    environmentVariables: [
      {
        name: 'EULA'
        value: 'true'
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
    storageAccountName: storage.name
    storageAccountKey: storage.listKeys().keys[0].value
  }
}


var overviewerContainer = {
  name: 'overviewer'
  properties: {
    image: 'mide/minecraft-overviewer'
    environmentVariables: [
      {
        name: 'MINECRAFT_VERSION'
        value: toLower(minecraftVersion)
      }
    ]
    volumeMounts: [
      {
        name: 'server'
        mountPath: '/home/minecraft/server'
        readOnly: true
      }
      {
        name: 'overviewer'
        mountPath: '/home/minecraft/render'
        readOnly: false
      }
    ]
    resources: {
      requests: {
        cpu: 1
        memoryInGB: 2
      }
    }
  }
}

var overviewerContainerVolume = {
  name: 'overviewer'
  azureFile: {
    readOnly: false
    shareName: overviewerShareName
    storageAccountName: storage.name
    storageAccountKey: storage.listKeys().keys[0].value
  }
}


/*
 * STORAGE
 */
resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource serverShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: serverShareResourceName
  properties: {
    accessTier: 'Hot'
    shareQuota: 16
  }
}

resource overviewerShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = if(overviewerEnabled) {
  name: overviewerShareResourceName
  properties: {
    accessTier: 'Hot'
    shareQuota: 256
  }
}

resource serverShareLock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: 'storageLock'
  scope: serverShare
  properties: {
    level: 'CanNotDelete'
    notes: 'Auto-created by azmc.bicep'
  }
}

resource overviewerShareLock 'Microsoft.Authorization/locks@2020-05-01' = if(overviewerEnabled) {
  name: 'overviewerShareLock'
  scope: overviewerShare
  properties: {
    level: 'CanNotDelete'
    notes: 'Auto-created by azmc.bicep'
  }
}

resource storageLock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: 'serverShareLock'
  scope: storage
  properties: {
    level: 'CanNotDelete'
    notes: 'Auto-created by azmc.bicep'
  }
}


/*
 * COMPUTE
 */
resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2022-09-01' = {
  name: containerGroupName
  location: location
  properties: {
    containers: overviewerEnabled ? [minecraftContainer, overviewerContainer] : [minecraftContainer]
    volumes: overviewerEnabled ? [minecraftContainerVolume, overviewerContainerVolume] : [minecraftContainerVolume]
    restartPolicy: 'OnFailure'
    osType: 'Linux'
    diagnostics: {
      logAnalytics: {
        workspaceId: logAnalyticsWorkspace.properties.customerId
        workspaceKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    ipAddress: {
      type: 'Public'
      dnsNameLabel: 'play${name}'
      ports: [
        {
          protocol: 'TCP'
          port: 25565
        }
      ]
    }
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

output joinHostname string = containerGroup.properties.ipAddress.fqdn 
output containerGroupName string = containerGroup.name
