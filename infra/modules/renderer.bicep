param location string
param projectName string

param containerEnvironmentName string
param mapRendererStorageAccountName string = ''

var rendererContainerJobName = 'cj-${projectName}-renderer'
var renderingContainerImage = 'ghcr.io/ginomessmer/azmc/map-renderer:main'


resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: mapRendererStorageAccountName
}

resource containerEnvironment 'Microsoft.App/managedEnvironments@2023-08-01-preview' existing = {
  name: containerEnvironmentName

  resource blueMapWebStorage 'storages' = if (mapRendererStorageAccountName != '') {
    name: 'bluemap-web'
    properties: {
      azureFile: {
        accessMode: 'ReadWrite'
        shareName: 'web'
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
          storageType: 'AzureFile'
          name: 'minecraft-server'
        }
        {
          storageType: 'AzureFile'
          name: 'bluemap-web'
        }
      ]
      containers: [
        {
          volumeMounts: [
            {
              mountPath: '/app/world'
              subPath: 'world'
              volumeName: 'minecraft-server'
            }
            {
              mountPath: '/app/web'
              volumeName: 'bluemap-web'
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
