param Location string = resourceGroup().location
param Name string = 'azmc'

resource storage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: Name
  location: Location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource serverShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-09-01' = {
  name: '${storage.name}/default/server'
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-03-01' = {
  name: Name
  location: Location
  properties: {
    containers: [
      {
        name: 'server'
        properties: {
          image: 'nimmis/spigot'
          ports: [
            {
              port: 25565
            }
          ]
          environmentVariables: [
            {
              name: 'EULA'
              value: 'true'
            }
          ]
          volumeMounts: [
            {
              name: 'server'
              mountPath: '/minecraft'
            }
          ]
          resources: {
            requests: {
              cpu: 2
              memoryInGB: 4
            }
          }
        }
      }
    ]
    volumes: [
      {
        name: 'server'
        azureFile: {
          storageAccountName: storage.name
          shareName: serverShare.name
          storageAccountKey: storage.listKeys().keys[0].value
        }
      }
    ]
    restartPolicy: 'OnFailure'
    osType: 'Linux'
    ipAddress: {
      type: 'Public'
      ports: [
        {
          protocol: 'TCP'
          port: 25565
        }
      ]
    }
  }
}

