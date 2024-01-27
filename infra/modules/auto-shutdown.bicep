param location string
param projectName string

param containerGroupName string
param roleDefinitionId string

var logicAppName = 'logic-${projectName}-auto-shutdown'

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' existing = {
  name: containerGroupName
}

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
  }
}

// Role assignment
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(logicApp.id, roleDefinitionId)
  scope: containerGroup
  properties: {
    principalId: logicApp.identity.principalId
    roleDefinitionId: roleDefinitionId
  }
}
