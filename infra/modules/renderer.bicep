param location string
param projectName string

param deployRendererJob bool

param renderingStorageAccountName string

param containerEnvironmentId string

var rendererContainerJobName = 'caj-${projectName}-renderer'

var renderingContainerImage = 'ghcr.io/ginomessmer/azmc/map-renderer:main'


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
resource rendererContainerJob 'Microsoft.App/jobs@2023-05-01' = if (deployRendererJob) {
  name: rendererContainerJobName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    environmentId: containerEnvironmentId
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
