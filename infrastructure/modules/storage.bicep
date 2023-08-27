param location string
param skuName string = 'Standard_LRS'

param projectName string

var storageAccountName = '${projectName}sa'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
}

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

output storageAccountName string = storageAccount.name
output serverFileShareName string = serverFileShare.name
