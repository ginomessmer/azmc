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
    // Public access is intentional — this account serves the web map to players
    allowBlobPublicAccess: true
    supportsHttpsTrafficOnly: true
  }
  
  resource fileServices 'fileServices' = {
    name: 'default'

    resource webShare 'shares' = {
      name: const.renderer.webShareName
      properties: {
        shareQuota: 256
      }
    }

    resource blueMapShare 'shares' = {
      name: const.renderer.blueMapShareName
      properties: {
        shareQuota: 32
      }
    }

    resource caddyConfigShare 'shares' = {
      name: const.renderer.caddyShareName
      properties: {
        shareQuota: 1
      }
    }
  }
}

output storageAccountPublicMapResourceId string = storageAccountPublicMap.id
output storageAccountPublicMapName string = storageAccountPublicMap.name

output caddyShareName string = storageAccountPublicMap::fileServices::caddyConfigShare.name
