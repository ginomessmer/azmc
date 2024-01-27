param location string
param projectName string

@description('The name of the Log Analytics workspace to use for the bot')
param workspaceName string

var containerEnvironmentName = 'cae-${projectName}'

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

output containerEnvironmentName string = containerEnvironment.name
output containerEnvironmentId string = containerEnvironment.id
