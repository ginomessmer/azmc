param name string = 'azmc'
param location string

param acceptEula bool

targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-${name}'
  location: location
}

module main 'main.bicep' = {
  name: 'main'
  scope: resourceGroup
  params: {
    name: name
    acceptEula: acceptEula
    // TODO
  }
}
