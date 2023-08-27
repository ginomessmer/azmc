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

  resource serverFileShare 'fileServices' = {
    name: 'default'

    resource share 'shares' = {
      name: 'server'
      properties: {
        accessTier: 'Hot'
        shareQuota: 256
      }
    }
  }
}
