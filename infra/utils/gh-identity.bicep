// Use this template (independently) to create a user-assigned managed identity for GitHub Actions.
// E.g. az deployment group create -f infra/utils/gh-identity.bicep -g <<YOUR RG NAME>> -p name <<PROJECT NAME SIMILIAR USED IN MAIN>> 

param name string
param location string = resourceGroup().location

param repo string = 'ginomessmer/azmc'
param environment string = 'development'

var const = loadJsonContent('../const.json')

var subject = 'repo:${repo}:environment:${environment}'
var identityName = '${const.abbr.managedIdentity}-${name}-gh-actions'


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

// Role assignments — Contributor + User Access Administrator in place of the broader Owner role
var contributorRoleDefinitionId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var userAccessAdminRoleDefinitionId = '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9'

resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: contributorRoleDefinitionId
}

resource userAccessAdminRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: userAccessAdminRoleDefinitionId
}

resource contributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(identity.id, contributorRoleDefinition.id)
  scope: resourceGroup()
  properties: {
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: contributorRoleDefinition.id
  }
}

resource userAccessAdminRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(identity.id, userAccessAdminRoleDefinition.id)
  scope: resourceGroup()
  properties: {
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: userAccessAdminRoleDefinition.id
  }
}

// Lock
resource identityLock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: 'identityLock'
  scope: identity
  dependsOn: [
    contributorRoleAssignment
    userAccessAdminRoleAssignment
  ]
  properties: {
    level: 'ReadOnly'
    notes: 'Lock to prevent accidental modification to this identity to keep GitHub actions working.'
  }
}

output identityPrincipalId string = identity.properties.principalId
output subscriptionId string = subscription().subscriptionId
output tenantId string = tenant().tenantId
