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

// resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
//   name: '${containerEnvironmentName}-diag'
//   scope: containerEnvironment
//   properties: {
//     workspaceId: workspace.id
//     logs: [
//       {
//         category: 'ContainerAppConsoleLogs'
//         enabled: true
//       }
//       {
//         category: 'ContainerAppSystemLogs'
//         enabled: true
//       }
//     ]
//   }
// }

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
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: renderingStorageAccountName
}

resource storageKeyOperatorServiceRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('81a9662b-bebf-436f-a333-f67b29880f12', rendererContainerJob.id)
  scope: storageAccount
  properties: {
    principalId: rendererContainerJob.identity.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '81a9662b-bebf-436f-a333-f67b29880f12')
    principalType: 'ServicePrincipal'
  }
}
