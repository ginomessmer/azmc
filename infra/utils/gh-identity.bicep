// Use this template (independently) to create a user-assigned managed identity for GitHub Actions.
// E.g. az deployment group create -f infra/utils/gh-identity.bicep -g <<YOUR RG NAME>> -p name <<PROJECT NAME SIMILIAR USED IN MAIN>> 

param name string
param location string = resourceGroup().location

param repo string = 'ginomessmer/azmc'
param environment string = 'development'

var subject = 'repo:${repo}:environment:${environment}'
var identityName = 'id-${name}-gh-actions'


resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: identityName
  location: location

  resource federatedCredentials 'federatedIdentityCredentials' = {
    name: 'github-actions_default'
    properties: {
      audiences: [
        'api://AzureADTokenExchange'
      ]
      issuer: 'https://token.actions.githubusercontent.com'
      subject: subject
    }
  }
}

// Role assignment
var ownerRoleDefinitionName = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
resource ownerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: ownerRoleDefinitionName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(identity.id, ownerRoleDefinition.id)
  scope: resourceGroup()
  properties: {
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: ownerRoleDefinition.id
  }
}

// Lock
resource identityLock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: 'identityLock'
  scope: identity
  dependsOn: [
    roleAssignment
  ]
  properties: {
    level: 'ReadOnly'
    notes: 'Lock to prevent accidental modification to this identity to keep GitHub actions working.'
  }
}

output identityPrincipalId string = identity.properties.principalId
output subscriptionId string = subscription().subscriptionId
output tenantId string = tenant().tenantId
