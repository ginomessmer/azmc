param location string
param projectName string

param containerGroupName string
param roleDefinitionId string

param recurrence object = {
  frequency: 'Day'
  interval: '1'
  schedule: {
    hours: [
      '3'
    ]
    minutes: [
      0
    ]
  }
}

var const = loadJsonContent('../const.json')

var logicAppName = '${const.abbr.logicApp}-${projectName}-auto-shutdown'

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
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      actions: {
        'HTTP_-_POST_-_ARM_Container_Stop': {
          inputs: {
            authentication: {
              type: 'ManagedServiceIdentity'
            }
            method: 'POST'
            uri: '${environment().resourceManager}@{parameters(\'containerId\')}/stop?api-version=${containerGroup.apiVersion}'
          }
          runAfter: {}
          type: 'Http'
        }
      }
      contentVersion: '1.0.0.0'
      parameters: {
        containerId: {
          defaultValue: containerGroup.id
          type: 'String'
        }
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        Recurrence: {
          evaluatedRecurrence: recurrence
          recurrence: recurrence
          type: 'Recurrence'
        }
      }
    }
    parameters: {
      '$connections': {
        value: {}
      }
    }
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
