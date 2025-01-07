param containerAppName string

var const = loadJsonContent('../const.json')

param clientId string

resource containerApp 'Microsoft.App/containerApps@2024-10-02-preview' existing = {
  name: containerAppName
}

resource containerAppAuth 'Microsoft.App/containerApps/authConfigs@2024-10-02-preview' = {
  name: 'current'
  parent: containerApp

  properties: {
    platform: {
      enabled: true
    }
    globalValidation: {
      unauthenticatedClientAction: 'RedirectToLoginPage'
      redirectToProvider: 'AzureActiveDirectory'
    }
    login: {
      tokenStore: {
        enabled: true
      }
    }
    identityProviders: {
      azureActiveDirectory: {
        registration: {
          openIdIssuer: 'https://login.microsoftonline.com/consumers/v2.0'
          clientId: clientId
          clientSecretSettingName: const.auth.clientSecretName
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
