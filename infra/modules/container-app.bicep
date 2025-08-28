// ===========================================
// Container App Module
// ===========================================
// Reusable module for deploying containerized services in the DevOps platform.
// Provides consistent configuration for ingress, scaling, security, and monitoring.

@description('Container app name')
param name string

@description('Deployment location')
param location string

@description('Resource tags')
param tags object

@description('Container Apps environment ID')
param environmentId string

@description('Container image')
param image string

@description('Target port for the container')
param targetPort int

@description('CPU and memory resources')
param resources object

@description('Environment variables')
param environmentVariables array = []

@description('Secret references')
param secrets array = []

@description('Volume mounts')
param volumeMounts array = []

@description('Volumes')
param volumes array = []

@description('Managed identity resource ID')
param managedIdentityId string

@description('Minimum replicas')
param minReplicas int = 1

@description('Maximum replicas')
param maxReplicas int = 3

@description('Enable Application Insights')
param enableApplicationInsights bool = false

@description('Application Insights connection string')
param applicationInsightsConnectionString string = ''

// ===========================================
// Container App Resource
// ===========================================

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    environmentId: environmentId
    configuration: {
      ingress: {
        external: true
        targetPort: targetPort
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
        transport: 'auto'
      }
      secrets: secrets
    }
    template: {
      containers: [
        {
          name: 'main'
          image: image
          resources: {
            cpu: json(resources.cpu)
            memory: resources.memory
          }
          env: union(environmentVariables, enableApplicationInsights ? [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: applicationInsightsConnectionString
            }
          ] : [])
          volumeMounts: volumeMounts
          probes: [
            {
              type: 'readiness'
              httpGet: {
                path: '/'
                port: targetPort
              }
              initialDelaySeconds: 10
              periodSeconds: 10
              successThreshold: 1
              failureThreshold: 3
              timeoutSeconds: 10
            }
            {
              type: 'liveness'
              httpGet: {
                path: '/'
                port: targetPort
              }
              initialDelaySeconds: 30
              periodSeconds: 30
              successThreshold: 1
              failureThreshold: 3
              timeoutSeconds: 10
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '50'
              }
            }
          }
        ]
      }
      volumes: volumes
    }
  }
}

// ===========================================
// Outputs
// ===========================================

@description('Container app FQDN')
output fqdn string = containerApp.properties.configuration.ingress.fqdn

@description('Container app resource ID')
output id string = containerApp.id

@description('Container app name')
output name string = containerApp.name
