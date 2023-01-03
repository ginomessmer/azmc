param location string = resourceGroup().location
param name string = 'azmc'
param minecraftVersion string = 'LATEST'
param memorySize int = 3
param cpuCores int = 2
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


var containers = overviewerEnabled ? [minecraftContainer, overviewerContainer] : [minecraftContainer]
var containerVolumes = overviewerEnabled ? [minecraftContainerVolume, overviewerContainerVolume] : [minecraftContainerVolume]


/*
 * STORAGE
 */
resource storage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: 'azmc${uniqueString(name)}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource serverShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-09-01' = {
  name: '${storage.name}/default/${serverShareName}'
  properties: {
    accessTier: 'Hot'
    shareQuota: 1024
  }
}

resource overviewerShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-09-01' = if(overviewerEnabled) {
  name: '${storage.name}/default/${overviewerShareName}'
  properties: {
    accessTier: 'Hot'
    shareQuota: 256
  }
}

resource storageLock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: 'lock'
  scope: storage
  properties: {
    level: 'CanNotDelete'
    notes: 'Auto-created by azmc.bicep'
  }
}


/*
 * COMPUTE
 */
resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-03-01' = {
  name: 'ci-${name}'
  location: location
  properties: {
    containers: containers
    volumes: containerVolumes
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

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: 'la-${name}-workspace'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

output joinHostname string = containerGroup.properties.ipAddress.fqdn 
output containerGroupName string = containerGroup.name
