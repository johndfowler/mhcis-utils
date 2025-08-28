# Shade - Cloud-Native Utility Platform

<p align="center">
  <img src="assets/logo/shade-logo.png" alt="Shade Logo" width="200"/>
</p>

A comprehensive, security-hardened utility platform built on Azure Container Apps with monitoring, visualization, file management, and remote development capabilities.

## 🏗️ Architecture Overview

This platform deploys a modern, cloud-native infrastructure with the following components:

### Core Services

- **Uptime Kuma**: Primary monitoring and alerting service
- **Grafana**: Data visualization and dashboards (optional)
- **Filebrowser**: Web-based file management (optional)
- **Code Server**: VS Code in the browser for remote development (optional)

### Infrastructure Components

- **Azure Container Apps**: Serverless containerized workloads
- **Azure Key Vault**: Centralized secrets management
- **User-Assigned Managed Identity**: Secure, keyless authentication
- **Azure Virtual Network**: Network isolation and security
- **Azure Storage Account**: Persistent data storage with RBAC
- **Application Insights**: Comprehensive monitoring and telemetry
- **Log Analytics**: Centralized logging and analytics

## 🔒 Security Features

- ✅ **Managed Identity Authentication**: Eliminates storage account keys
- ✅ **Key Vault Integration**: Secure secrets management with RBAC
- ✅ **VNet Integration**: Network isolation and private communication
- ✅ **Private Endpoints**: Optional for production environments
- ✅ **TLS Encryption**: HTTPS-only communication
- ✅ **Storage Security**: Disabled shared key access, encryption at rest
- ✅ **RBAC Authorization**: Role-based access control throughout

## 📁 Project Structure

```
├── azure.yaml                    # Azure Developer CLI configuration
├── infra/
│   ├── main.bicep                # Main infrastructure template
│   ├── main.parameters.json      # Deployment parameters
│   └── modules/
│       └── container-app.bicep   # Reusable container app module
└── README.md                     # This file
```

## 🚀 Quick Deployment

### Prerequisites

1. Azure CLI installed and authenticated
2. Azure Developer CLI (azd) installed
3. Appropriate Azure subscription permissions

### Option 1: Azure Developer CLI (Recommended)

```bash
# Initialize and deploy
azd init
azd up
```

### Option 2: Azure CLI

```bash
# Create resource group
az group create --name rg-shade-dev-eus-01 --location eastus

# Deploy infrastructure
az deployment group create \
  --resource-group rg-shade-dev-eus-01 \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json
```

## ⚙️ Configuration

### Environment Variables

Configure the platform through parameters in `infra/main.parameters.json`:

- `prefix`: Resource name prefix (configurable)
- `environment`: Target environment (dev/test/staging/prod)
- `regionAbbr`: Azure region abbreviation
- `monitoringService.enabled`: Enable Uptime Kuma monitoring
- `visualizationService.enabled`: Enable Grafana dashboards
- `fileManagementService.enabled`: Enable file browser
- `developmentService.enabled`: Enable VS Code server

### Service Configuration

Each service can be independently enabled/disabled and configured:

- CPU and memory resource allocation
- Container images and versions
- Network ports and ingress settings

### Security Configuration

- `enablePrivateEndpoints`: Enable private endpoints for production
- `isTestMode`: Reduce resources for development/testing
- Key Vault soft delete and purge protection settings

## 🎛️ Utility Services

### Uptime Kuma (Default)

- **Purpose**: Website and service monitoring
- **Default Port**: 3001
- **Features**: Real-time monitoring, alerting, status pages
- **Storage**: Persistent data in Azure Files

### Grafana (Optional)

- **Purpose**: Data visualization and dashboards
- **Default Port**: 3000
- **Credentials**: admin / (auto-generated secure password in Key Vault)
- **Features**: Dashboard creation, data source integration

### Filebrowser (Optional)

- **Purpose**: Web-based file management
- **Default Port**: 80
- **Features**: Upload, download, file organization
- **Storage**: Access to shared Azure Files storage

### Code Server (Optional)

- **Purpose**: VS Code in the browser
- **Default Port**: 8080
- **Credentials**: (auto-generated secure password in Key Vault)
- **Features**: Full VS Code experience, terminal access

## 🔍 Monitoring & Observability

### Application Insights Integration

- Automatic telemetry collection
- Performance monitoring
- Dependency tracking
- Custom metrics and alerts

### Log Analytics

- Centralized logging
- 30-day retention (configurable)
- Kusto query language (KQL) support
- Integration with Azure Monitor

### Health Checks

- Readiness probes for all services
- Automatic service recovery
- Container restart policies

## 🛡️ Best Practices Implemented

### Security

- No hardcoded secrets or passwords
- Managed identity for all Azure service authentication
- Network isolation with VNet integration
- TLS encryption for all communication
- RBAC permissions following least privilege principle

### Architecture

- Modular Bicep templates for reusability
- User-defined types for parameter validation
- CAF (Cloud Adoption Framework) naming conventions
- Environment-specific configurations
- Comprehensive resource tagging

### Operations

- Infrastructure as Code with Bicep
- Automated deployment with Azure Developer CLI
- Container health monitoring
- Automatic scaling capabilities
- Centralized configuration management

## 📊 Resource Naming Convention

Following Azure CAF standards:

- Resource Group: `rg-{workload}-{environment}-{region}-{instance}`
- Storage Account: `st{workload}{env}{region}{instance}`
- Key Vault: `kv-{workload}-{environment}-{region}-{instance}`
- Container Apps: `ca-{workload}-{environment}-{region}-{instance}`

## 🔧 Management Commands

### View Deployed Resources

```bash
az resource list --resource-group rg-shade-dev-eus-01 --output table
```

### Access Key Vault Secrets

```bash
az keyvault secret list --vault-name kv-shade-dev-eus-01
```

### View Application Logs

```bash
az containerapp logs show --name ca-shade-dev-eus-01 --resource-group rg-shade-dev-eus-01
```

### Monitor with Application Insights

```bash
az monitor app-insights query --app appi-shade-dev-eus-01 --analytics-query "requests | limit 10"
```

## 🧹 Cleanup

### Remove All Resources

```bash
az group delete --name rg-shade-dev-eus-01 --yes --no-wait
```

## 📈 Scaling & Production

For production deployments:

1. Set `environment` to "prod" in parameters
2. Enable `enablePrivateEndpoints`
3. Disable `isTestMode`
4. Configure appropriate resource allocation
5. Set up monitoring alerts and dashboards
6. Implement backup and disaster recovery procedures

## 🤝 Contributing

This template follows Azure best practices and is designed for extensibility:

- Add new services by creating additional container app modules
- Extend security with additional Key Vault secrets
- Implement CI/CD with Azure DevOps or GitHub Actions
- Customize networking with additional subnets or private endpoints

## 📝 Version History

- **1.0.0**: Initial comprehensive utility platform with security hardening
  - Managed identity authentication
  - Key Vault integration
  - VNet isolation
  - Multi-service architecture
  - Comprehensive monitoring

## 📞 Support

For issues, questions, or contributions:

1. Review Azure documentation for Container Apps and related services
2. Check Azure Resource Health for service status
3. Use Application Insights for application-level troubleshooting
4. Consult Azure support for infrastructure issues
