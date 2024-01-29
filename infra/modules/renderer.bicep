param location string
param projectName string

param containerEnvironmentName string
param mapRendererStorageAccountName string = ''

var rendererContainerJobName = 'cj-${projectName}-renderer'
var renderingContainerImage = 'ghcr.io/ginomessmer/azmc/map-renderer:main'

var const = loadJsonContent('../const.json')

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
      replicaTimeout: 1800
      triggerType: 'schedule'
      replicaRetryLimit: 0
      scheduleTriggerConfig: {
        cronExpression: '0 0 * * 0'
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
          ]
          name: 'renderer'
          image: renderingContainerImage
          env: [
            {
              name: 'AZURE_STORAGE_ACCOUNT'
              value: storageAccount.name
            }
            {
              name: 'AZURE_STORAGE_ACCOUNT_RG_NAME'
              value: resourceGroup().name
            }
            {
              name: 'AZURE_LOGIN_TYPE'
              value: 'managed-identity'
            }
          ]
          resources: {
            cpu: 2
            memory: '4.0Gi'
          }
        }
      ]
    }
  }
}

// Assign roles to container job
var roleDefinitionName = '81a9662b-bebf-436f-a333-f67b29880f12'
resource storageKeyOperatorServiceRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(rendererContainerJob.id, roleDefinitionName)
  scope: storageAccount
  properties: {
    principalId: rendererContainerJob.identity.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionName)
    principalType: 'ServicePrincipal'
  }
}
