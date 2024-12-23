param managedEnvironmentName string
param webMapContainerAppName string
param webMapHostName string
param location string = resourceGroup().location

resource environment 'Microsoft.App/managedEnvironments@2024-10-02-preview' existing = {
  name: managedEnvironmentName

  resource managedCertificate 'managedCertificates@2024-10-02-preview' = if(!empty(webMapHostName)) {
    name: 'certifcate'
    properties: {
      domainControlValidation: 'HTTP'
      subjectName: webMapHostName
    }
  }
}

resource webMapContainerApp 'Microsoft.App/containerApps@2024-10-02-preview' = {
  name: webMapContainerAppName
  location: location

  properties: {
    configuration: {
      ingress: {
        customDomains: [
          {
            name: webMapHostName
            certificateId: environment::managedCertificate.id
            bindingType: 'Auto'
          }
        ]
      }
    }
  }
}
