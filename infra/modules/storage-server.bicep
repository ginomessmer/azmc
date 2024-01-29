param location string
param skuName string = 'Standard_ZRS'

param projectName string

var normalizedProjectName = replace(projectName, '-', '')
var storageAccountName = 'st${normalizedProjectName}'
var storageAccountNameServer = '${storageAccountName}server'

var const = loadJsonContent('../const.json')

var serverFileShareName = const.minecraftServerFileShareName

// Server container
resource storageAccountServer 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountNameServer
  location: location
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }

  // Server file share
  resource serverFileServices 'fileServices' = {
    name: 'default'
    properties: {
      shareDeleteRetentionPolicy: {
        days: 30
        enabled: true
      }
    }

    resource serverFileShare 'shares' = {
      name: serverFileShareName
      properties: {
        accessTier: 'Hot'
        shareQuota: 256
      }
    }
  }
}

// Locks
resource storageAccountLock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: 'storageAccountLock'
  scope: storageAccountServer
  properties: {
    level: 'CanNotDelete'
    notes: 'This lock is to prevent accidental deletion of the storage account. This storage account contains the server files. Managed by azmc.'
  }
}

resource serverFileShareLock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: 'serverFileShareLock'
  scope: storageAccountServer::serverFileServices::serverFileShare
  properties: {
    level: 'CanNotDelete'
    notes: 'This lock is to prevent accidental deletion of the server file share. This file share contains the server files. Managed by azmc.'
  }
}


output storageAccountServerResourceId string = storageAccountServer.id
output storageAccountServerName string = storageAccountServer.name
output storageAccountFileShareServerName string = storageAccountServer::serverFileServices::serverFileShare.name
output storageAccountId string = storageAccountServer.id
