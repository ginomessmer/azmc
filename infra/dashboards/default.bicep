param location string
param projectName string

param minecraftServerContainerInstanceName string
param discordBotContainerAppId string
param serverStorageAccountId string

resource minecraftServerContainerInstance 'Microsoft.ContainerInstance/containerGroups@2023-05-01' existing = {
  name: minecraftServerContainerInstanceName
}

resource mainDashboard 'Microsoft.Portal/dashboards@2020-09-01-preview' = {
  name: 'dbrd-${projectName}'
  location: location
  tags: {
    'hidden-title': 'Minecraft Server Dashboard'
  }
  properties: {
    lenses: [
      {
        order: 0
        parts: [
          {
            position: {
              x: 0
              y: 0
              colSpan: 2
              rowSpan: 1
            }
            metadata: {
              inputs: [
                {
                  name: 'id'
                  value: minecraftServerContainerInstance.id
                  isOptional: true
                }
                {
                  name: 'resourceId'
                  isOptional: true
                }
                {
                  name: 'menuid'
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/ResourcePart'
              asset: {
                idInputName: 'id'
              }
              deepLink: '#@${tenant().tenantId}/resource${minecraftServerContainerInstance.id}/overview'
            }
          }
          {
            position: {
              x: 2
              y: 0
              colSpan: 5
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'options'
                  value: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: minecraftServerContainerInstance.id
                          }
                          name: 'CpuUsage'
                          aggregationType: 4
                          namespace: 'microsoft.containerinstance/containergroups'
                          metricVisualization: {
                            displayName: 'CPU Usage'
                          }
                        }
                      ]
                      title: 'Avg CPU Usage for Minecraft Server Container'
                      titleKind: 1
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                      }
                      timespan: {
                        relative: {
                          duration: 86400000
                        }
                        showUTCTime: false
                        grain: 1
                      }
                    }
                  }
                  isOptional: true
                }
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: minecraftServerContainerInstance.id
                          }
                          name: 'CpuUsage'
                          aggregationType: 4
                          namespace: 'microsoft.containerinstance/containergroups'
                          metricVisualization: {
                            displayName: 'CPU Usage'
                          }
                        }
                      ]
                      title: 'Avg CPU Usage for Minecraft Server Container'
                      titleKind: 1
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                        disablePinning: true
                      }
                    }
                  }
                }
              }
            }
          }
          {
            position: {
              x: 7
              y: 0
              colSpan: 5
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'options'
                  value: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: minecraftServerContainerInstance.id
                          }
                          name: 'MemoryUsage'
                          aggregationType: 4
                          namespace: 'microsoft.containerinstance/containergroups'
                          metricVisualization: {
                            displayName: 'Memory Usage'
                          }
                        }
                      ]
                      title: 'Avg Memory Usage for Minecraft Server Container'
                      titleKind: 1
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                      }
                      timespan: {
                        relative: {
                          duration: 86400000
                        }
                        showUTCTime: false
                        grain: 1
                      }
                    }
                  }
                  isOptional: true
                }
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: minecraftServerContainerInstance.id
                          }
                          name: 'MemoryUsage'
                          aggregationType: 4
                          namespace: 'microsoft.containerinstance/containergroups'
                          metricVisualization: {
                            displayName: 'Memory Usage'
                          }
                        }
                      ]
                      title: 'Avg Memory Usage for Minecraft Server Container'
                      titleKind: 1
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                        disablePinning: true
                      }
                    }
                  }
                }
              }
            }
          }
          {
            position: {
              x: 12
              y: 0
              colSpan: 2
              rowSpan: 1
            }
            metadata: {
              inputs: [
                {
                  name: 'id'
                  value: discordBotContainerAppId
                  isOptional: true
                }
                {
                  name: 'resourceId'
                  isOptional: true
                }
                {
                  name: 'menuid'
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/ResourcePart'
              asset: {
                idInputName: 'id'
              }
              deepLink: '#@${tenant().tenantId}/resource${discordBotContainerAppId}/containerapp'
            }
          }
          {
            position: {
              x: 14
              y: 0
              colSpan: 5
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'options'
                  value: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: discordBotContainerAppId
                          }
                          name: 'Requests'
                          aggregationType: 1
                          namespace: 'microsoft.app/containerapps'
                          metricVisualization: {
                            displayName: 'Requests'
                            resourceDisplayName: 'Discord Bot'
                          }
                        }
                      ]
                      title: 'Sum Requests for Discord Bot'
                      titleKind: 1
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                      }
                      timespan: {
                        relative: {
                          duration: 86400000
                        }
                        showUTCTime: false
                        grain: 1
                      }
                    }
                  }
                  isOptional: true
                }
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: discordBotContainerAppId
                          }
                          name: 'Requests'
                          aggregationType: 1
                          namespace: 'microsoft.app/containerapps'
                          metricVisualization: {
                            displayName: 'Requests'
                            resourceDisplayName: 'Discord Bot'
                          }
                        }
                      ]
                      title: 'Sum Requests for Discord Bot'
                      titleKind: 1
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                        disablePinning: true
                      }
                    }
                  }
                }
              }
              filters: {
                MsPortalFx_TimeRange: {
                  model: {
                    format: 'local'
                    granularity: 'auto'
                    relative: '1440m'
                  }
                }
              }
            }
          }
          {
            position: {
              x: 0
              y: 1
              colSpan: 2
              rowSpan: 2
            }
            metadata: {
              inputs: []
              type: 'Extension/HubsExtension/PartType/ArmActions'
              settings: {
                content: {
                  settings: {
                    title: ''
                    subtitle: ''
                    uri: '${minecraftServerContainerInstance.id}/start?api-version=${minecraftServerContainerInstance.apiVersion}'
                    name: 'Start server'
                    data: ''
                  }
                }
              }
            }
          }
          {
            position: {
              x: 0
              y: 3
              colSpan: 2
              rowSpan: 2
            }
            metadata: {
              inputs: []
              type: 'Extension/HubsExtension/PartType/ArmActions'
              settings: {
                content: {
                  settings: {
                    title: ''
                    subtitle: ''
                    uri: '${minecraftServerContainerInstance.id}/stop?api-version=${minecraftServerContainerInstance.apiVersion}'
                    name: 'Stop server'
                    data: ''
                  }
                }
              }
            }
          }
          {
            position: {
              x: 2
              y: 4
              colSpan: 5
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'options'
                  value: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: minecraftServerContainerInstance.id
                          }
                          name: 'NetworkBytesReceivedPerSecond'
                          aggregationType: 4
                          namespace: 'microsoft.containerinstance/containergroups'
                          metricVisualization: {
                            displayName: 'Network Bytes Received Per Second'
                          }
                        }
                        {
                          resourceMetadata: {
                            id: minecraftServerContainerInstance.id
                          }
                          name: 'NetworkBytesTransmittedPerSecond'
                          aggregationType: 4
                          namespace: 'microsoft.containerinstance/containergroups'
                          metricVisualization: {
                            displayName: 'Network Bytes Transmitted Per Second'
                          }
                        }
                      ]
                      title: 'Minecraft Server Network Activity'
                      titleKind: 2
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                      }
                      timespan: {
                        relative: {
                          duration: 86400000
                        }
                        showUTCTime: false
                        grain: 1
                      }
                    }
                  }
                  isOptional: true
                }
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: minecraftServerContainerInstance.id
                          }
                          name: 'NetworkBytesReceivedPerSecond'
                          aggregationType: 4
                          namespace: 'microsoft.containerinstance/containergroups'
                          metricVisualization: {
                            displayName: 'Network Bytes Received Per Second'
                          }
                        }
                        {
                          resourceMetadata: {
                            id: minecraftServerContainerInstance.id
                          }
                          name: 'NetworkBytesTransmittedPerSecond'
                          aggregationType: 4
                          namespace: 'microsoft.containerinstance/containergroups'
                          metricVisualization: {
                            displayName: 'Network Bytes Transmitted Per Second'
                          }
                        }
                      ]
                      title: 'Minecraft Server Network Activity'
                      titleKind: 2
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                        disablePinning: true
                      }
                    }
                  }
                }
              }
            }
          }
          {
            position: {
              x: 7
              y: 4
              colSpan: 5
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'options'
                  value: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: serverStorageAccountId
                          }
                          name: 'Egress'
                          aggregationType: 1
                          namespace: 'microsoft.storage/storageaccounts'
                          metricVisualization: {
                            displayName: 'Egress'
                          }
                        }
                        {
                          resourceMetadata: {
                            id: serverStorageAccountId
                          }
                          name: 'Ingress'
                          aggregationType: 1
                          namespace: 'microsoft.storage/storageaccounts'
                          metricVisualization: {
                            displayName: 'Ingress'
                          }
                        }
                      ]
                      title: 'Storage Account Network Activity'
                      titleKind: 2
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                      }
                      timespan: {
                        relative: {
                          duration: 86400000
                        }
                        showUTCTime: false
                        grain: 1
                      }
                    }
                  }
                  isOptional: true
                }
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: serverStorageAccountId
                          }
                          name: 'Egress'
                          aggregationType: 1
                          namespace: 'microsoft.storage/storageaccounts'
                          metricVisualization: {
                            displayName: 'Egress'
                          }
                        }
                        {
                          resourceMetadata: {
                            id: serverStorageAccountId
                          }
                          name: 'Ingress'
                          aggregationType: 1
                          namespace: 'microsoft.storage/storageaccounts'
                          metricVisualization: {
                            displayName: 'Ingress'
                          }
                        }
                      ]
                      title: 'Storage Account Network Activity'
                      titleKind: 2
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                        disablePinning: true
                      }
                    }
                  }
                }
              }
            }
          }
        ]
      }
    ]
  }
}
