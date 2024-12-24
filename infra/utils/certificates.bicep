param managedEnvironmentName string
param webMapHostName string
param location string = resourceGroup().location

resource managedEnvironment 'Microsoft.App/managedEnvironments@2024-10-02-preview' existing = {
  name: managedEnvironmentName

  resource managedCertificate 'managedCertificates@2024-10-02-preview' = if(!empty(webMapHostName)) {
    name: 'certifcate'
    location: location
    properties: {
      domainControlValidation: 'HTTP'
      subjectName: webMapHostName
    }
  }
}

output managedCertificateId string = managedEnvironment::managedCertificate.id
