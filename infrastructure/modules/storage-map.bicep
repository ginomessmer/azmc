param location string
param skuName string = 'Standard_LRS'

param projectName string

var normalizedProjectName = replace(projectName, '-', '')
var storageAccountName = 'st${normalizedProjectName}'
var storageAccountNamePublicMap = '${storageAccountName}map'

// Map container
resource storageAccountPublicMap 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountNamePublicMap
  location: location
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    supportsHttpsTrafficOnly: true
  }

  // Map container
  resource publicMapBlobServices 'blobServices' = {
    name: 'default'

    resource publicMapContainer 'containers' = {
      name: 'map'
      properties: {
        publicAccess: 'Blob'
      }
    }
  }
}

output storageAccountPublicMapResourceId string = storageAccountPublicMap.id
output storageAccountPublicMapName string = storageAccountPublicMap.name
output storageAccountPublicMapContainerName string = storageAccountPublicMap::publicMapBlobServices.name

