param Location string = resourceGroup().location
param Name string = 'azmc'
param MinecraftVersion string = 'LATEST'
param MemorySize int = 3
param CpuCores int = 2
param OverviewerEnabled bool = true

@allowed([
  'TRUE'
  'FALSE'
])
param IsAutostopEnabled string = 'TRUE'

var ServerShareName = 'server'
var OverviewerShareName = 'overviewer'
var ServerMountPath = '/data'
var ServerType = 'SPIGOT'

// Container settings
var OverviewerContainer = {
  name: 'overviewer'
  properties: {
    image: 'mide/minecraft-overviewer'
    environmentVariables: [
      {
        name: 'MINECRAFT_VERSION'
        value: toLower(MinecraftVersion)
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

var OverviewerContainerVolume = {
  name: 'overviewer'
  azureFile: {
    readOnly: false
    shareName: OverviewerShareName
    storageAccountName: storage.name
    storageAccountKey: storage.listKeys().keys[0].value
  }
}


/*
 * STORAGE
 */
resource storage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: Name
  location: Location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource serverShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-09-01' = {
  name: '${storage.name}/default/${ServerShareName}'
  properties: {
    accessTier: 'Hot'
    shareQuota: 1024
  }
}

resource overviewerShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-09-01' = if(OverviewerEnabled) {
  name: '${storage.name}/default/${OverviewerShareName}'
  properties: {
    accessTier: 'Hot'
    shareQuota: 256
  }
}

/*
 * COMPUTE
 */
resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-03-01' = {
  name: Name
  location: Location
  properties: {
    containers: [
      {
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
              value: ServerType
            }
            {
              name: 'VERSION'
              value: MinecraftVersion
            }
            {
              name: 'ENABLE_AUTOSTOP'
              value: IsAutostopEnabled
            }
            {
              name: 'MEMORY'
              value: '${MemorySize}G'
            }
          ]
          volumeMounts: [
            {
              name: 'server'
              mountPath: ServerMountPath
              readOnly: false
            }
          ]
          resources: {
            requests: {
              cpu: CpuCores
              memoryInGB: MemorySize + 1
            }
          }
        }
      }
      OverviewerEnabled ? OverviewerContainer : {}
    ]
    volumes: [
      {
        name: 'server'
        azureFile: {
          readOnly: false
          shareName: ServerShareName
          storageAccountName: storage.name
          storageAccountKey: storage.listKeys().keys[0].value
        }
      }
      OverviewerEnabled ? OverviewerContainerVolume : {}
    ]
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
      dnsNameLabel: 'play${Name}'
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
  name: '${Name}-workspace'
  location: Location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

output joinHostname string = containerGroup.properties.ipAddress.fqdn 
