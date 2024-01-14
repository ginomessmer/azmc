param location string
param skuName string = 'Standard_LRS'

param projectName string

var storageAccountName = 'st${projectName}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
}

// Server file share
resource serverFileServices 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource serverFileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  parent: serverFileServices
  name: 'server'
  properties: {
    accessTier: 'Hot'
    shareQuota: 256
  }
}

// Map container
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource mapContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: 'map'
  parent: blobServices
  properties: {
    publicAccess: 'Container'
  }
}

// Locks
resource storageAccountLock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: 'storageAccountLock'
  scope: storageAccount
  properties: {
    level: 'CanNotDelete'
    notes: 'This lock is to prevent accidental deletion of the storage account. Managed by azmc.'
  }
}

resource serverFileShareLock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: 'serverFileShareLock'
  scope: serverFileShare
  properties: {
    level: 'CanNotDelete'
    notes: 'This lock is to prevent accidental deletion of the server file share. Managed by azmc.'
  }
}

output storageAccountResourceId string = storageAccount.id
output storageAccountName string = storageAccount.name
output serverFileShareName string = serverFileShare.name
