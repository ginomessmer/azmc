param location string
param projectName string

var const = loadJsonContent('../const.json')

var normalizedProjectName = replace(projectName, '-', '')
var storageAccountName = '${const.abbr.storageAccount}${normalizedProjectName}res'

resource storageAccountResources 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    supportsHttpsTrafficOnly: true
  }

  resource blobServices 'blobServices' = {
    name: 'default'

    resource resourcePackContainer 'containers' = {
      name: 'packs'
      properties: {
        publicAccess: 'Blob'
      }
    }
  } 
}

output storageAccountName string = storageAccountResources.name
output storageAccountResourcePackEndpoint string = '${storageAccountResources.properties.primaryEndpoints.blob}/${storageAccountResources::blobServices::resourcePackContainer.name}'

