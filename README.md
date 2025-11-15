# Azure DevOps Pipeline for AKS Deployment
## Complete CI/CD Solution with .NET Sample Applications

---

## 📖 Overview

This repository contains a complete Azure DevOps CI/CD pipeline setup for deploying .NET applications to Azure Kubernetes Service (AKS). It implements a GitFlow branching strategy with automated PR validation, multi-environment deployments, and production approval gates.

### ✨ Features

- **GitFlow Strategy**: Branch-based deployments (dev → qa → staging → production)
- **PR Validation**: Automated build, test, and Docker validation before merge
- **Multi-Environment**: Separate namespaces for dev, qa, staging, and prod
- **Helm Deployments**: Kubernetes deployments using Helm charts
- **Container Registry**: Azure Container Registry (ACR) integration
- **Approval Gates**: Manual approval required for production deployments
- **Sample Applications**: Two .NET 8 Web APIs (Frontend & Backend)

---

## 📁 Monorepo Structure

```
Azure-Devops-Pipeline/ (Monorepo Root)
│
├── .pipeline-templates/                # ⭐ SHARED pipeline templates
│   ├── pr-validation-template.yml      # PR validation for all services
│   └── environment-deployment-template.yml  # Deployment for all services
│
├── services/                           # ⭐ ALL MICROSERVICES (50+)
│   ├── frontend-api/
│   │   ├── Program.cs
│   │   ├── FrontendController.cs
│   │   ├── FrontendApi.csproj
│   │   ├── Dockerfile
│   │   ├── values.yaml
│   │   └── azure-pipeline.yml          # Service-specific pipeline
│   │
│   ├── backend-api/
│   │   ├── Program.cs
│   │   ├── BackendController.cs
│   │   ├── BackendApi.csproj
│   │   ├── Dockerfile
│   │   ├── values.yaml
│   │   └── azure-pipeline.yml
│   │
│   └── ... (add your 48+ services here)
│
├── shared/                             # ⭐ SHARED resources
│   ├── helm-charts/
│   │   └── plain-app-chart/           # Reusable Helm chart
│   ├── libraries/                     # Shared .NET libraries (future)
│   └── configs/                       # Shared configurations (future)
│
├── docs/                               # Documentation (optional)
├── refactored-pipelines/               # Legacy - for reference
└── README.md                           # This file
```

### Key Directories:
- **`.pipeline-templates/`** - Pipeline templates shared by ALL services
- **`services/`** - Each microservice in its own folder with path-based triggers
- **`shared/`** - Shared resources (Helm charts, libraries, configs)

---

## 🚀 Quick Start

### Prerequisites

1. **Azure Resources** (via Terraform):
   - AKS cluster
   - Azure Container Registry (ACR)
   - Virtual Network and Subnets

2. **Development Tools**:
   - .NET 8 SDK
   - Docker Desktop
   - kubectl
   - Helm 3.x
   - Azure CLI
   - Git

3. **Azure DevOps**:
   - Azure DevOps Organization and Project
   - Pipeline creation permissions

### Getting Started with Monorepo

1. **Clone the Repository** (Once for all services!)
   ```bash
   git clone <your-repo-url>
   cd Azure-Devops-Pipeline
   # You now have access to ALL 50+ microservices!
   ```

2. **Follow the Setup Guide** (⭐ START HERE)
   ```bash
   # Complete setup guide - everything you need!
   code SETUP-GUIDE.md
   ```

3. **Provision Infrastructure**
   ```bash
   # Navigate to your Terraform directory
   cd <path-to-terraform-config>
   
   # Initialize and apply
   terraform init
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

4. **Configure Azure DevOps**
   - Create service connections (ACR, AKS for each environment)
   - Create environments (Dev, QA, Staging, Production)
   - Set up branch policies
   - Create pipelines for frontend and backend APIs

5. **Test the Pipeline**
   - Create feature branch
   - Make changes to sample apps
   - Create PR to dev branch
   - Observe PR validation
   - Merge and watch deployment

---

## 📚 Documentation

### ⭐ **[SETUP-GUIDE.md](SETUP-GUIDE.md)** - Complete Setup Guide (START HERE!)

Everything you need in one place:
- 🛠️ Prerequisites and verification scripts
- ☁️ Azure infrastructure setup (AKS + ACR)
- 🔧 Azure DevOps configuration (pipelines, connections, environments)
- 🚀 First deployment walkthrough
- ➕ Adding new microservices
- 💼 Daily workflows (feature development, promotions, rollbacks)
- 🐞 Comprehensive troubleshooting
- 📚 Command reference (Git, kubectl, Helm, Azure CLI, Docker, .NET)

**⏱️ Estimated Time:** 2-3 hours (first deployment)

### Pipeline Templates

- **PR Validation Template** (`templates/pr-validation-template.yml`)
  - Builds solution
  - Runs unit tests
  - Validates Docker build
  - Publishes test results

- **Environment Deployment Template** (`templates/environment-deployment-template.yml`)
  - Builds and tests code
  - Builds Docker image
  - Pushes to ACR
  - Deploys to AKS using Helm

---

## 🏗️ Architecture

### Pipeline Flow

```
Developer → Feature Branch → PR to Dev → PR Validation
                                    ↓
                              PR Approved & Merged
                                    ↓
                         Auto-Deploy to Dev Environment
                                    ↓
                          Test & Create PR to QA
                                    ↓
                         Auto-Deploy to QA Environment
                                    ↓
                       Test & Create PR to Staging
                                    ↓
                      Auto-Deploy to Staging Environment
                                    ↓
                        Test & Create PR to Main
                                    ↓
                          Build & Wait for Approval
                                    ↓
                       Deploy to Production Environment
```

### Sample Applications

#### Frontend API
- .NET 8 Web API
- Endpoints:
  - `GET /health` - Health check
  - `GET /api/frontend/info` - Service information
  - `GET /api/frontend/backend-status` - Backend connectivity check
  - `GET /api/frontend/data` - Fetch data from backend
- Communicates with Backend API
- Swagger UI enabled

#### Backend API
- .NET 8 Web API
- Endpoints:
  - `GET /health` - Health check
  - `GET /api/backend/info` - Service information
  - `GET /api/backend/data` - Returns sample data
  - `POST /api/backend/process` - Process data
  - `GET /api/backend/health/detailed` - Detailed health status
- Swagger UI enabled

---

## 🔧 Configuration

### Update ACR URL

Before deploying, update the ACR URL in the following files:

1. `sample-apps/frontend-api/frontend-api-pipeline.yml` (line 42)
2. `sample-apps/backend-api/backend-api-pipeline.yml` (line 42)
3. `sample-apps/frontend-api/values.yaml` (line 4)
4. `sample-apps/backend-api/values.yaml` (line 4)

Replace `your-acr.azurecr.io` with your actual ACR URL.

### Update Service Connection Names

Update service connection names in the templates if yours differ:

- `templates/environment-deployment-template.yml`
  - Line 36: `CAIAKSDev` → Your Dev K8s connection
  - Line 39: `CAIAKSQA` → Your QA K8s connection
  - Line 42: `CAIAKSStaging` → Your Staging K8s connection
  - Line 45: `cai-aks-prod` → Your Prod K8s connection
  - Line 124: `MyCAI Microservices ACR PROD` → Your ACR connection

---

## 🧪 Testing Locally

### Build and Run Frontend API

```bash
cd sample-apps/frontend-api

# Restore packages
dotnet restore

# Build
dotnet build

# Run
dotnet run

# Test endpoints
curl http://localhost:5000/health
curl http://localhost:5000/api/frontend/info
```

### Build and Run Backend API

```bash
cd sample-apps/backend-api

# Restore packages
dotnet restore

# Build
dotnet build

# Run
dotnet run

# Test endpoints
curl http://localhost:5000/health
curl http://localhost:5000/api/backend/info
curl http://localhost:5000/api/backend/data
```

### Build Docker Images Locally

```bash
# Frontend
cd sample-apps/frontend-api
docker build -t frontend-api:local .
docker run -p 8080:8080 frontend-api:local

# Backend
cd sample-apps/backend-api
docker build -t backend-api:local .
docker run -p 8081:8080 backend-api:local
```

---

## 🔐 Security Considerations

- **Secrets Management**: Use Azure Key Vault or Azure DevOps Secure Files
- **Service Connections**: Use service principals with minimum required permissions
- **Branch Protection**: Enable branch policies on all protected branches
- **RBAC**: Implement proper RBAC in AKS clusters
- **Network Policies**: Configure Kubernetes network policies
- **Image Scanning**: Add container vulnerability scanning to pipeline

---

## 🐛 Troubleshooting

### Common Issues

1. **Pipeline fails at build stage**
   - Check .NET SDK version
   - Verify NuGet restore configuration
   - Check project file syntax

2. **Docker build fails**
   - Verify Dockerfile syntax
   - Check base image availability
   - Ensure all files are copied correctly

3. **Helm deployment fails**
   - Verify Kubernetes service connection
   - Check namespace exists
   - Validate Helm chart syntax
   - Ensure ACR integration is configured

4. **Pods not starting**
   - Check pod logs: `kubectl logs <pod-name> -n <namespace>`
   - Verify image can be pulled from ACR
   - Check resource limits
   - Verify health check configuration

For detailed troubleshooting, see the [SETUP-GUIDE.md](SETUP-GUIDE.md#troubleshooting).

---

## 📝 Best Practices

✅ **Always use PRs** - Never push directly to protected branches  
✅ **Write unit tests** - Ensure tests pass before merging  
✅ **Test in all environments** - Don't skip environments  
✅ **Use semantic commits** - Clear, descriptive commit messages  
✅ **Monitor deployments** - Watch logs during and after deployment  
✅ **Implement health checks** - Ensure Kubernetes can verify pod health  
✅ **Set resource limits** - Define CPU and memory limits  
✅ **Version your images** - Use build numbers for traceability  
✅ **Document changes** - Keep documentation up to date  
✅ **Plan for rollbacks** - Know how to revert deployments  

---

## 🤝 Contributing

1. Create a feature branch from `dev`
2. Make your changes
3. Create a PR to `dev`
4. Wait for PR validation to pass
5. Get approval from reviewers
6. Merge to `dev`

---

## 📞 Support

For issues or questions:

1. Check the troubleshooting section in the guides
2. Review Azure DevOps pipeline logs
3. Check Kubernetes pod logs
4. Review Helm release status
5. Contact the DevOps team

---

## 📄 License

[Your License Here]

---

## 🎯 Next Steps

1. **Add More Services**: Follow the pattern to add additional microservices
2. **Implement Ingress**: Replace LoadBalancer with Ingress controller
3. **Add Monitoring**: Integrate Azure Monitor, Application Insights, or Prometheus
4. **Implement Secrets Management**: Use Azure Key Vault CSI driver
5. **Add Databases**: Deploy and integrate database services
6. **Implement API Gateway**: Add API Management or Kong
7. **Enhanced Testing**: Add integration tests, load tests, security scans

---

## ⭐ Key Features Summary

| Feature | Description | Status |
|---------|-------------|--------|
| GitFlow Strategy | Branch-based deployments | ✅ Implemented |
| PR Validation | Automated build and test | ✅ Implemented |
| Multi-Environment | Dev, QA, Staging, Prod | ✅ Implemented |
| Container Registry | ACR integration | ✅ Implemented |
| Orchestration | Kubernetes with Helm | ✅ Implemented |
| Approval Gates | Production approvals | ✅ Implemented |
| Sample Apps | Frontend & Backend APIs | ✅ Implemented |
| Documentation | Complete setup guides | ✅ Implemented |
| Health Checks | Kubernetes probes | ✅ Implemented |
| Resource Management | CPU/Memory limits | ✅ Implemented |

---

**Ready to deploy? Start with the [SETUP-GUIDE.md](SETUP-GUIDE.md)!** 🚀
