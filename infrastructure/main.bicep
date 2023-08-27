param location string = resourceGroup().location
param projectName string = 'azmc'

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    projectName: projectName
  }
}
