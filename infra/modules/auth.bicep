param containerAppName string
var containerAppAuthName = '${containerAppName}-auth'

param clientId string

resource containerApp 'Microsoft.App/containerApps@2024-10-02-preview' existing = {
  name: containerAppName
}

resource containerAppAuth 'Microsoft.App/containerApps/authConfigs@2024-10-02-preview' = {
  name: containerAppAuthName
  parent: containerApp

  properties: {
    platform: {
      enabled: true
    }
    globalValidation: {
      unauthenticatedClientAction: 'RedirectToLoginPage'
      redirectToProvider: 'AzureActiveDirectory'
    }
    identityProviders: {
      azureActiveDirectory: {
        registration: {
          openIdIssuer: 'https://login.microsoftonline.com/consumers/v2.0'
          clientId: clientId
          clientSecretSettingName: 'client-secret'
        }
        validation: {
          defaultAuthorizationPolicy: {
            allowedApplications: [
              clientId
            ]
          }
        }
      }
    }
  }
}
