param botPrincipalId string

resource containerInstanceManagerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(resourceGroup().id, 'containerInstanceManagerRoleDefinition')
  scope: resourceGroup()
  properties: {
    roleName: 'Game Server Container Manager'
    description: 'Created by azmc.bicep'
    assignableScopes: [
      resourceGroup().id
    ]
    permissions: [
      {
        actions: [
          'Microsoft.ContainerInstance/containerGroups/start/action'
          'Microsoft.ContainerInstance/containerGroups/stop/action'
          'Microsoft.ContainerInstance/containerGroups/restart/action'
          'Microsoft.ContainerInstance/*/read'
        ]
      }
    ]
  }
}

resource managerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, 'bot-manager')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: containerInstanceManagerRoleDefinition.id
    principalId: botPrincipalId
    principalType: 'ServicePrincipal'
  }
}