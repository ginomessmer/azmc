param location string
param skuName string = 'Standard_LRS'

param projectName string

var normalizedProjectName = replace(projectName, '-', '')
var storageAccountName = 'st${normalizedProjectName}'
var storageAccountNamePublicMap = '${storageAccountName}map'

var const = loadJsonContent('../const.json')

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
  
  resource fileServices 'fileServices' = {
    name: 'default'

    resource webShare 'shares' = {
      name: const.renderer.webShareName
    }

    resource blueMapShare 'shares' = {
      name: const.renderer.blueMapShareName
    }
  }
}

output storageAccountPublicMapResourceId string = storageAccountPublicMap.id
output storageAccountPublicMapName string = storageAccountPublicMap.name
