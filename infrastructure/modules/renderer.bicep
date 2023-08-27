param location string
param projectName string

param renderingStorageAccountName string
param workspaceName string

var containerEnvironmentName = '${projectName}-ce'
var rendererContainerJobName = '${projectName}-renderer-job'

var renderingContainerImage = 'ghcr.io/ginomessmer/azmc/map-renderer:main'

// Dependencies
resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

// Container Environment
resource containerEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerEnvironmentName
  location: location

  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: workspace.properties.customerId
        sharedKey: listKeys(workspace.id, workspace.apiVersion).primarySharedKey
      }
    }
  }
}

// Container Job for renderer
resource rendererContainerJob 'Microsoft.App/jobs@2023-05-01' = {
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
      containers: [
        {
          name: 'renderer'
          image: renderingContainerImage
          env: [
            {
              name: 'AZURE_STORAGE_ACCOUNT'
              value: renderingStorageAccountName
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
