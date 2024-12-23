param location string
param projectName string

param containerEnvironmentName string
param mapRendererStorageAccountName string = ''

@description('The schedule for the renderer job. The renderer job will be triggered according to this schedule.')
@allowed([
  'weekly'
  'daily'
  'hourly'
  'every5Minutes'
])
param schedule string = 'weekly'

var rendererContainerJobName = '${const.abbr.containerJob}-${projectName}-renderer'
var renderingContainerImage = 'ghcr.io/bluemap-minecraft/bluemap:latest'

param webMapHostName string = ''
var webMapContainerAppName = '${const.abbr.containerApp}-${projectName}-map-web'
var webImageName = 'caddy:2.8'

var const = loadJsonContent('../const.json')

var cronSchedules = {
  weekly: '0 0 * * 0'
  daily: '0 0 * * *'
  hourly: '0 * * * *'
  every5Minutes: '*/5 * * * *'
}

var cronExpression = cronSchedules[schedule]

resource rendererStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: mapRendererStorageAccountName
}

resource containerEnvironment 'Microsoft.App/managedEnvironments@2023-08-01-preview' existing = {
  name: containerEnvironmentName

  // Web map
  resource mapWebStorage 'storages' =  {
    name: const.containerEnvMapWebStorageName
    properties: {
      azureFile: {
        accessMode: 'ReadWrite'
        shareName: const.renderer.webShareName
        accountName: rendererStorageAccount.name
        accountKey: rendererStorageAccount.listKeys().keys[0].value
      }
    }
  }

  // Blue map
  resource blueMapStorage 'storages' = {
    name: const.containerEnvBlueMapStorageName
    properties: {
      azureFile: {
        accessMode: 'ReadWrite'
        shareName: const.renderer.blueMapShareName
        accountName: rendererStorageAccount.name
        accountKey: rendererStorageAccount.listKeys().keys[0].value
      }
    }
  }

  // Caddy config
  resource caddyStorage 'storages' = {
    name: const.containerEnvCaddyStorageName
    properties: {
      azureFile: {
        accessMode: 'ReadWrite'
        shareName: const.renderer.caddyShareName
        accountName: rendererStorageAccount.name
        accountKey: rendererStorageAccount.listKeys().keys[0].value
      }
    }
  }

  resource managedCertificate 'managedCertificates' = if(!empty(webMapHostName)) {
    name: 'certifcate'
    location: location
    properties: {
      domainControlValidation: 'HTTP'
      subjectName: webMapHostName
    }
  }
}

// Container Job for renderer
resource rendererContainerJob 'Microsoft.App/jobs@2023-08-01-preview' = {
  name: rendererContainerJobName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    environmentId: containerEnvironment.id
    configuration: {
      replicaTimeout: 3600
      triggerType: 'schedule'
      replicaRetryLimit: 0
      scheduleTriggerConfig: {
        cronExpression: cronExpression
      }
    }
    template: {
      volumes: [
        {
          // Minecraft server
          storageName: const.containerEnvMinecraftServerStorageName
          storageType: 'AzureFile'
          name: const.containerEnvMinecraftServerStorageName
        }
        {
          // Web map
          storageName: const.containerEnvMapWebStorageName
          storageType: 'AzureFile'
          name: const.containerEnvMapWebStorageName
        }
        {
          // Blue map
          storageName: const.containerEnvBlueMapStorageName
          storageType: 'AzureFile'
          name: const.containerEnvBlueMapStorageName
        }
      ]
      containers: [
        {
          volumeMounts: [
            {
              mountPath: '/app/world'
              subPath: 'world'
              volumeName: const.containerEnvMinecraftServerStorageName
            }
            {
              mountPath: '/app/web'
              volumeName: const.containerEnvMapWebStorageName
            }
            {
              mountPath: '/app/config'
              volumeName: const.containerEnvBlueMapStorageName
              subPath: 'config'
            }
            {
              mountPath: '/app/data'
              volumeName: const.containerEnvBlueMapStorageName
              subPath: 'data'
            }
          ]
          name: 'renderer'
          image: renderingContainerImage
          args: [ '-r' ]
          resources: {
            cpu: 2
            memory: '4.0Gi'
          }
        }
      ]
    }
  }
}

resource webMapContainerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: webMapContainerAppName
  location: location
  properties: {
    environmentId: containerEnvironment.id
    configuration: {
      ingress: {
        allowInsecure: false
        targetPort: 80
        external: true
        customDomains: !empty(webMapHostName) ? [
          {
            name: webMapHostName
          }
        ] : []
      }
    }
    template: {
      volumes: [
        {
          // Web map
          storageName: const.containerEnvMapWebStorageName
          storageType: 'AzureFile'
          name: const.containerEnvMapWebStorageName
        }
        {
          // Caddy
          storageName: const.containerEnvCaddyStorageName
          storageType: 'AzureFile'
          name: const.containerEnvCaddyStorageName
        }
      ]
      containers: [
        {
          name: 'web'
          image: webImageName
          volumeMounts: [
            {
              mountPath: '/srv'
              volumeName: const.containerEnvMapWebStorageName
            }
            {
              mountPath: '/etc/caddy'
              volumeName: const.containerEnvCaddyStorageName
              subPath: 'config'
            }
            {
              mountPath: '/data'
              volumeName: const.containerEnvCaddyStorageName
              subPath: 'data'
            }
          ]
          resources:{
            cpu: '0.25'
            memory: '0.5Gi'
          }
        }
      ]
    }
  }
}

output webMapContainerAppName string = webMapContainerApp.name
output rendererContainerJobName string = rendererContainerJob.name

output webMapFqdn string = webMapContainerApp.properties.latestRevisionFqdn
