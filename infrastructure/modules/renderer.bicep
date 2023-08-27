param location string
param projectName string
param renderingStorageAccountName string

var containerEnvironmentName = '${projectName}-ce'
var rendererContainerJobName = '${projectName}-renderer-job'

var renderingContainerImage = ''

// Container Environment
resource containerEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerEnvironmentName
  location: location
}

// Container Job for renderer
resource rendererContainerJob 'Microsoft.App/jobs@2023-05-01' = {
  name: rendererContainerJobName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    configuration: {
      replicaTimeout: 1800
      triggerType: 'schedule'
      replicaRetryLimit: 0
      scheduleTriggerConfig: {
        cronExpression: '0 0 * * 0'
      }
    }
    template: {
      containers: [
        {
          image: renderingContainerImage
          env: [
            {
              name: 'AZURE_STORAGE_ACCOUNT'
              value: renderingStorageAccountName
            }
          ]
        }
      ]
    }
  }
}
