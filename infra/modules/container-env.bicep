param location string
param projectName string

@description('The name of the Log Analytics workspace to use for the bot')
param workspaceName string

param minecraftServerStorageAccountName string

var containerEnvironmentName = 'cae-${projectName}'

var const = loadJsonContent('../const.json')

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource minecraftServerStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: minecraftServerStorageAccountName
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
        sharedKey: workspace.listKeys().primarySharedKey
      }
    }
  }

  // Storages
  resource minecraftServerStorage 'storages' = {
    name: const.containerEnvMinecraftServerStorageName
    properties: {
      azureFile: {
        accessMode: 'ReadWrite'
        shareName: const.minecraftServer.shareName
        accountName: minecraftServerStorageAccount.name
        accountKey: minecraftServerStorageAccount.listKeys().keys[0].value
      }
    }
  }
}

output containerEnvironmentName string = containerEnvironment.name
output containerEnvironmentId string = containerEnvironment.id
