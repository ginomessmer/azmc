param location string
param projectName string

@description('The name of the Log Analytics workspace to use for the bot')
param workspaceName string

@description('(Optional) The name of the storage account to use for the map renderer. If not specified, the map renderer won\'t be attached.')
param mapRendererStorageAccountName string?

var containerEnvironmentName = 'cae-${projectName}'

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource mapRendererStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = if (mapRendererStorageAccountName != null) {
  name: mapRendererStorageAccountName!
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

  resource test 'storages' = if (mapRendererStorageAccountName != null) {
    name: 'bluemap-web'
    properties: {
      azureFile: {
        accessMode: 'ReadWrite'
        shareName: 'web'
        accountName: mapRendererStorageAccount.name
        accountKey: mapRendererStorageAccount.listKeys().keys[0].value
      }
    }
  }
}

output containerEnvironmentName string = containerEnvironment.name
output containerEnvironmentId string = containerEnvironment.id
