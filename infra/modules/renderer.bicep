param location string
param projectName string

param containerEnvironmentName string
param mapRendererStorageAccountName string = ''

@description('Whether to use CDN for the web map. This can improve performance, enables caching and supports compression, but may incur additional costs.')
param useCdn bool = true

param webMapHostName string = ''

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

var webMapContainerAppName = '${const.abbr.containerApp}-${projectName}-map-web'
var cdnName = '${const.abbr.cdn}-${projectName}-map-web'

var const = loadJsonContent('../const.json')

var cronSchedules = {
  weekly: '0 0 * * 0'
  daily: '0 0 * * *'
  hourly: '0 * * * *'
  every5Minutes: '*/5 * * * *'
}

var cronExpression = cronSchedules[schedule]

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
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
        accountName: storageAccount.name
        accountKey: storageAccount.listKeys().keys[0].value
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
        accountName: storageAccount.name
        accountKey: storageAccount.listKeys().keys[0].value
      }
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
      ]
      containers: [
        {
          name: 'web'
          image: 'nginx'
          volumeMounts: [
            {
              mountPath: '/usr/share/nginx/html'
              volumeName: const.containerEnvMapWebStorageName
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

resource cdn 'Microsoft.Cdn/profiles@2023-07-01-preview' = if (useCdn) {
  name: cdnName
  location: 'Global'
  sku: {
    name: 'Standard_Microsoft'
  }
  
  resource endpoint 'endpoints' = {
    name: '${projectName}-map'
    location: 'Global'
    properties: {
      originHostHeader: webMapContainerApp.properties.configuration.ingress.fqdn
      contentTypesToCompress: [
        'image/png'
        'application/json'
      ]
      isCompressionEnabled: true
      isHttpsAllowed: true
      queryStringCachingBehavior: 'UseQueryString'
      origins: [
        {
          name: 'map'
          properties: {
            hostName: webMapContainerApp.properties.configuration.ingress.fqdn
            httpPort: 80
            httpsPort: 443
            originHostHeader: webMapContainerApp.properties.configuration.ingress.fqdn
            priority: 1
            weight: 1000
            enabled: true
          }
        }
      ]
      deliveryPolicy: {
        rules: [
          {
            name: 'RedirectToHttps'
            conditions: [
              {
                name: 'RequestScheme'
                parameters: {
                  operator: 'Equal'
                  typeName: 'DeliveryRuleRequestSchemeConditionParameters'
                  matchValues: [ 'HTTP' ]
                  negateCondition: false
                }
              }
            ]
            actions: [
              {
                name: 'UrlRedirect'
                parameters: {
                  redirectType: 'Found'
                  typeName: 'DeliveryRuleUrlRedirectActionParameters'
                  destinationProtocol: 'Https'
                }
              }
            ]
            order: 1
          }
        ]
      }
    }

    resource domain 'customDomains' = if (webMapHostName != '') {
      name: replace(webMapHostName, '.', '-')
      properties: {
        hostName: webMapHostName
      }
    }
  }
}

output webMapContainerAppName string = webMapContainerApp.name
output rendererContainerJobName string = rendererContainerJob.name

output webMapFqdn string = useCdn ? cdn::endpoint.properties.hostName : webMapContainerApp.properties.latestRevisionFqdn
