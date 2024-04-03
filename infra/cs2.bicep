param location string = resourceGroup().location
param name string

@secure()
@description('Sets the Game Server Login Token for the server')
param gslt string

@secure()
@description('Sets the Steam Web API Key for the server required to download workshop mods')
param steamWebApiKey string


// Volume settings
param serverShareName string = 'server'
param serverStorageAccountName string

// Log Analytics settings
param workspaceName string

var const = loadJsonContent('./const.json')


module gameServer './modules/server.bicep' = {
  name: name
  params: {
    location: location
    projectName: name
    gamePort: 27015
    containers: [
      {
        name: 'server'
        properties: {
          environmentVariables: [
            {
              name: 'CSGO_GSLT'
              value: gslt
            }
            {
              name: 'CSGO_WS_API_KEY'
              value: steamWebApiKey
            }
          ] 
          image: const.images.cs2
          ports: [
            {
              port: 27015
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: '2'
              memoryInGB: 4
            }
          }
          volumeMounts: [
            {
              name: 'server'
              mountPath: '/home/csgo/server'
              readOnly: false
            }
          ]
        }
      }
    ]
    volumes: [
      {
        name: 'server'
        azureFile: {
          readOnly: false
          shareName: serverShareName
          storageAccountName: serverStorageAccountName
          storageAccountKey: storageAccount.listKeys().keys[0].value
        }
      }
    ]
    workspaceName: workspaceName
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: serverStorageAccountName
}
