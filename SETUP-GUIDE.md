# Complete Setup Guide
## Azure DevOps Pipeline for .NET Microservices on AKS

**⏱️ Estimated Time:** 2-3 hours (first deployment)

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Prerequisites](#prerequisites)
3. [Infrastructure Setup](#infrastructure-setup)
4. [Azure DevOps Configuration](#azure-devops-configuration)
5. [First Deployment](#first-deployment)
6. [Adding New Services](#adding-new-services)
7. [Daily Workflows](#daily-workflows)
8. [Troubleshooting](#troubleshooting)
9. [Command Reference](#command-reference)

---

## Quick Start

### What You'll Build

By the end of this guide, you'll have:

✅ Azure DevOps pipelines with GitFlow strategy  
✅ Two sample .NET 8 services deployed  
✅ Production approval gates configured  
✅ Monorepo ready for 50+ microservices  

### Monorepo Structure

```
Azure-Devops-Pipeline/
├── .pipeline-templates/           # Shared templates (all services use these)
│   ├── pr-validation-template.yml
│   └── environment-deployment-template.yml
├── services/                      # Your 50+ microservices go here
│   ├── frontend-api/
│   ├── backend-api/
│   └── ... (add more services)
├── shared/                        # Shared resources
│   └── helm-charts/
│       └── plain-app-chart/      # Reusable Helm chart
└── README.md
```

**Key Benefits:**
- ✅ One repository for all services
- ✅ Shared pipeline templates (no duplication)
- ✅ Path-based triggers (only changed services deploy)
- ✅ Easy cross-service refactoring

---

## Prerequisites

### Required Tools

Install and verify these tools before starting:

```powershell
# Verification script - run this first!
Write-Host "Checking Prerequisites..." -ForegroundColor Cyan

$checks = @{
    "Azure CLI" = { az --version 2>&1 | Select-String "azure-cli" }
    ".NET SDK" = { dotnet --version }
    "Docker" = { docker --version }
    "kubectl" = { kubectl version --client --short }
    "Helm" = { helm version --short }
    "Git" = { git --version }
}

foreach ($tool in $checks.Keys) {
    try {
        $result = & $checks[$tool]
        Write-Host "✅ $tool installed" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ $tool NOT found" -ForegroundColor Red
    }
}
```

**Download Links:**
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm 3.x](https://helm.sh/docs/intro/install/)
- [Git](https://git-scm.com/downloads)

### Required Access

- [ ] Azure Subscription (Contributor or Owner)
- [ ] Azure DevOps Organization ([Create Free](https://dev.azure.com))
- [ ] (Optional) Terraform installed for infrastructure provisioning

---

## Infrastructure Setup

### Step 1: Login and Configure Azure

```powershell
# Login to Azure
az login

# List subscriptions
az account list --output table

# Set active subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Verify
az account show --output table
```

### Step 2: Create Resource Group

```powershell
# Set variables (customize these!)
$RESOURCE_GROUP = "my-rg" 
$LOCATION = "azure region"
$ACR_NAME = "mytestacr690"
$AKS_NAME = "myaks"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION
```

### Step 3: Create Azure Container Registry

```powershell
# Create ACR
az acr create `
    --resource-group $RESOURCE_GROUP `
    --name $ACR_NAME `
    --sku Standard `
    --location $LOCATION

# Enable admin access (for easier setup)
az acr update --name $ACR_NAME --admin-enabled true

# Get ACR URL (SAVE THIS!)
$ACR_URL = az acr show --name $ACR_NAME --query loginServer --output tsv
Write-Host "📝 Your ACR URL: $ACR_URL" -ForegroundColor Yellow
```

### Step 5: Connect to AKS

```powershell
# Get credentials
az aks get-credentials `
    --resource-group $RESOURCE_GROUP `
    --name $AKS_NAME `
    --overwrite-existing

# Verify connection
kubectl cluster-info
kubectl get nodes
```

### Step 6: Create Namespaces

```powershell
# Create environment namespaces
$namespaces = @("dev", "qa", "staging", "prod")
foreach ($ns in $namespaces) {
    kubectl create namespace $ns
    Write-Host "✅ Created namespace: $ns" -ForegroundColor Green
}

# Verify
kubectl get namespaces
```

### Step 7: Verify ACR Integration

```powershell
# Check ACR is attached
az aks check-acr `
    --resource-group $RESOURCE_GROUP `
    --name $AKS_NAME `
    --acr $ACR_URL
```

**✅ Infrastructure Complete!** Save these values:
- ACR URL: `$ACR_URL`
- Resource Group: `$RESOURCE_GROUP`
- AKS Name: `$AKS_NAME`

---

## Azure DevOps Configuration

### Step 1: Create Project

1. Go to https://dev.azure.com
2. Click **New Project**
3. Configure:
   - **Name:** `Microservices-Platform` # Modify as needed
   - **Visibility:** Private
   - **Version control:** Git
4. Click **Create**

### Step 2: Push Repository

```powershell
cd C:\Users\Hp\OneDrive\Documents\GitHub\Azure-Devops-Pipeline

# Add Azure DevOps remote
git remote add azuredevops https://dev.azure.com/YOUR_ORG/Microservices-Platform/_git/Microservices-Platform

# Push code
git push azuredevops main
```

### Step 3: Create Branches

```powershell
# Create environment branches
git checkout -b dev && git push azuredevops dev
git checkout -b qa && git push azuredevops qa
git checkout -b staging && git push azuredevops staging
git checkout main

```

### Step 4: Create Service Connections

#### 4.1: Azure Container Registry Connection

1. Go to **Project Settings** (bottom left)
2. Click **Service connections** → **New service connection**
3. Select **Docker Registry** → **Next**
4. Configure:
   - **Registry type:** Azure Container Registry
   - **Subscription:** Select your subscription
   - **Azure container registry:** Select your ACR
   - **Service connection name:** `MyACR`
   - ✅ **Grant access to all pipelines**
5. Click **Save**

#### 4.2: Kubernetes Service Connections (Create 4)

For **each environment**, create a Kubernetes connection:

**Dev Environment:**
1. **New service connection** → **Kubernetes**
2. Configure:
   - **Authentication:** Azure Subscription
   - **Subscription:** Your subscription
   - **Cluster:** Your AKS cluster
   - **Namespace:** `dev`
   - **Service connection name:** `AKSDev`
   - ✅ **Grant access to all pipelines**
3. Click **Save**

**Repeat for:**
- **AKSQA** → namespace: `qa`
- **AKSStaging** → namespace: `staging`
- **AKSProd** → namespace: `prod`

**Verify:** You should now have **5 service connections** total.

### Step 5: Create Environments

1. Go to **Pipelines** → **Environments**
2. Click **New environment**

Create these 4 environments:

| Environment | Name | Approvals |
|-------------|------|-----------|
| Development | `Dev` | None |
| QA | `QA` | None |
| Staging | `Staging` | Optional |
| Production | `Production` | **Required** |

**Configure Production Approval:**
1. Click **Production** environment
2. Click **⋯** → **Approvals and checks**
3. Click **+** → **Approvals**
4. Add yourself as approver
5. Set minimum approvers: **1**
6. Click **Create**

### Step 6: Update Configuration Files

#### Update ACR URL in Service Pipelines

Each service pipeline needs your ACR URL configured. Update `services/frontend-api/azure-pipeline.yml` and `services/backend-api/azure-pipeline.yml`:


(Optional)

```powershell
# Update ACR URL automatically
$ACR_URL = az acr show --name $ACR_NAME --query loginServer --output tsv

(Get-Content services/frontend-api/azure-pipeline.yml) -replace 'your-acr\.azurecr\.io', $ACR_URL | Set-Content services/frontend-api/azure-pipeline.yml

(Get-Content services/backend-api/azure-pipeline.yml) -replace 'your-acr\.azurecr\.io', $ACR_URL | Set-Content services/backend-api/azure-pipeline.yml

# Commit changes
git add services/*/azure-pipeline.yml
git commit -m "Configure ACR URL for deployment"
git push azuredevops main
```

#### Verify Service Connection Names (Optional)

The pipelines use these default service connection names:

**In each service's `azure-pipeline.yml`:**
- `acrServiceConnection: 'MyACR'` (line 43)
- `k8sConnection: 'AKSDev'` (line 47)
- `k8sConnection: 'AKSQA'` (line 50)
- `k8sConnection: 'AKSStaging'` (line 53)
- `k8sConnection: 'AKSProd'` (line 56)

**In `.pipeline-templates/environment-deployment-template.yml`:**
- Default ACR: `MyACR` (line 29)
- Default Dev K8s: `AKSDev` (line 42)
- Default QA K8s: `AKSQA` (line 45)
- Default Staging K8s: `AKSStaging` (line 48)
- Default Prod K8s: `AKSProd` (line 51)

If you used different names in Step 4, update them in these files.

### Step 7: Create Pipelines

#### Create Frontend API Pipeline

1. Go to **Pipelines** → **Pipelines**
2. Click **New pipeline**
3. Select **Azure Repos Git**
4. Select repository: `Microservices-Platform`
5. Select **Existing Azure Pipelines YAML file**
6. Choose:
   - **Branch:** `main`
   - **Path:** `/services/frontend-api/azure-pipeline.yml`
7. Click **Continue** → **Save**
8. Click **⋯** → **Rename** → `frontend-api-pipeline`

#### Create Backend API Pipeline

Repeat steps above with:
- **Path:** `/services/backend-api/azure-pipeline.yml`
- **Name:** `backend-api-pipeline`

**✅ Azure DevOps Configuration Complete!**

---

## First Deployment

### Step 1: Create Feature Branch

```powershell
# Switch to dev
git checkout dev
git pull azuredevops dev

# Create feature branch
git checkout -b feature/test-deployment

# Make a small change
$file = "services/frontend-api/Program.cs"
$content = "// Testing deployment pipeline`n" + (Get-Content $file -Raw)
$content | Set-Content $file

# Commit and push
git add $file
git commit -m "test: Verify pipeline deployment"
git push azuredevops feature/test-deployment
```

### Step 2: Create Pull Request

**In Azure DevOps:**
1. Go to **Repos** → **Pull Requests**
2. Click **New pull request**
3. Configure:
   - **Source:** `feature/test-deployment`
   - **Target:** `dev`
4. Click **Create**

**Expected:** Pipeline automatically triggers for PR validation! ✨

### Step 3: Watch PR Validation

1. Go to **Pipelines** → **Pipelines**
2. Click the running pipeline
3. Watch stages execute:
   - ✅ Build .NET Service
   - ✅ Run Tests
   - ✅ Validate Docker Build

### Step 4: Merge and Deploy

1. Click **Approve** on PR
2. Click **Complete**
3. Select **Squash commit**
4. Click **Complete merge**

**Expected:** Pipeline triggers again and deploys to dev! 🚀

### Step 5: Verify Deployment

```powershell
# Check pods
kubectl get pods -n dev

# Check services
kubectl get svc -n dev

# Check Helm release
helm list -n dev

# View logs
kubectl logs -l app=frontend-api -n dev --tail=50
```

### Step 6: Test the Application

```powershell
# Port forward to local machine
kubectl port-forward svc/frontend-api 8080:80 -n dev

# In another terminal, test endpoints
curl http://localhost:8080/health
curl http://localhost:8080/api/frontend/info

# Open Swagger UI
Start-Process "http://localhost:8080/swagger"
```

**✅ First Deployment Complete!** 🎉

---

## Adding New Services

### Quick Service Setup

```powershell
# 1. Create service directory
cd services
New-Item -Path "user-service" -ItemType Directory
cd user-service

# 2. Create .NET project
dotnet new webapi -n UserService
dotnet new xunit -n UserService.Tests
dotnet new sln -n UserService
dotnet sln add UserService UserService.Tests

# 3. Copy templates from existing service
Copy-Item ..\frontend-api\Dockerfile .
Copy-Item ..\frontend-api\values.yaml .
Copy-Item ..\frontend-api\azure-pipeline.yml .

# 4. Update azure-pipeline.yml
# - Change service name to "user-service"
# - Update path triggers to "services/user-service/**"
# - Update image name to "user-service"

# 5. Update values.yaml
# - Change image repository to "your-acr.azurecr.io/user-service"
# - Adjust resources as needed

# 6. Commit and push
git checkout dev
git checkout -b feature/add-user-service
git add services/user-service
git commit -m "feat: Add user-service"
git push origin feature/add-user-service

# 7. Create PR to dev in Azure DevOps
# 8. Create pipeline in Azure DevOps pointing to services/user-service/azure-pipeline.yml
```

### Service Structure Template

Every service should have:

```
services/your-service/
├── Program.cs                    # Main application
├── Controllers/                  # API controllers
├── YourService.csproj           # Project file
├── YourService.Tests/           # Unit tests
├── Dockerfile                    # Container definition
├── values.yaml                   # Helm values
└── azure-pipeline.yml           # Pipeline configuration
```

### Path-Based Triggers

Each service pipeline only triggers when its files change:

```yaml
trigger:
  paths:
    include:
    - services/your-service/**      # Only this service
    - shared/helm-charts/**         # Or shared charts
    - .pipeline-templates/**        # Or shared templates
```

**Result:** Changing one service doesn't trigger all 50+ pipelines! ✨

---

## Daily Workflows

### Start New Feature

```powershell
git checkout dev
git pull origin dev
git checkout -b feature/my-feature
# Make changes
git add .
git commit -m "feat: Add new feature"
git push origin feature/my-feature
# Create PR to dev in Azure DevOps
```

### Promote to QA

**In Azure DevOps:**
1. Create PR from `dev` → `qa`
2. Wait for validation
3. Merge PR
4. Watch deployment to QA namespace

### Promote to Staging

**In Azure DevOps:**
1. Create PR from `qa` → `staging`
2. Wait for validation
3. Merge PR
4. Watch deployment to Staging namespace

### Deploy to Production

**In Azure DevOps:**
1. Create PR from `staging` → `main`
2. Wait for validation
3. Merge PR
4. Go to pipeline run
5. Click **Review** and **Approve**
6. Watch deployment to Production namespace

### Rollback Deployment

```powershell
# Check release history
helm history frontend-api -n prod

# Rollback to previous version
helm rollback frontend-api -n prod

# Or rollback to specific revision
helm rollback frontend-api 3 -n prod
```

---

## Troubleshooting

### Issue: Pipeline Fails at "Build Docker Image"

**Symptoms:** Authentication or ACR access errors

**Solution:**
```powershell
# Verify ACR connection
az acr login --name $ACR_NAME

# Re-attach ACR to AKS
az aks update `
    --resource-group $RESOURCE_GROUP `
    --name $AKS_NAME `
    --attach-acr $ACR_NAME
```

### Issue: Pods Stuck in "ImagePullBackOff"

**Symptoms:** Pods can't pull image from ACR

**Solution:**
```powershell
# Check pod details
kubectl describe pod <pod-name> -n dev

# Verify ACR integration
az aks check-acr `
    --resource-group $RESOURCE_GROUP `
    --name $AKS_NAME `
    --acr $ACR_URL

# Create image pull secret if needed
kubectl create secret docker-registry acr-secret `
    --docker-server=$ACR_URL `
    --docker-username=$(az acr credential show --name $ACR_NAME --query username -o tsv) `
    --docker-password=$(az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv) `
    --namespace=dev
```

### Issue: LoadBalancer External IP Stuck "Pending"

**Symptoms:** Service External-IP shows `<pending>`

**Solutions:**
```powershell
# Option 1: Wait (Azure provisioning takes 2-5 minutes)
kubectl get svc -n dev --watch

# Option 2: Use port-forward instead
kubectl port-forward svc/frontend-api 8080:80 -n dev

# Option 3: Change to ClusterIP
kubectl patch svc frontend-api -n dev -p '{"spec":{"type":"ClusterIP"}}'
```

### Issue: Pipeline Can't Find Template

**Symptoms:** "Template file not found" error

**Solution:**
- Ensure template path starts with `/`: `/.pipeline-templates/pr-validation-template.yml`
- Verify files exist in repository
- Check you're on the correct branch

### Issue: Multiple Pipelines Trigger

**Symptoms:** All pipelines run when you change one service

**Solution:**
Check path filters in pipeline YAML - they should be specific:
```yaml
paths:
  include:
  - services/frontend-api/**  # ✅ Correct (specific)
  - services/**               # ❌ Wrong (too broad)
```

---

## Command Reference

### Git Commands

```powershell
# Clone repo
git clone <repo-url>

# Create feature branch
git checkout dev
git checkout -b feature/my-feature

# Commit changes
git add .
git commit -m "feat: Description"
git push origin feature/my-feature

# Update from dev
git checkout dev
git pull origin dev
git checkout feature/my-feature
git merge dev

# Delete branch
git branch -d feature/my-feature
```

### kubectl Commands

```powershell
# Get resources
kubectl get pods -n dev
kubectl get svc -n dev
kubectl get deployments -n dev

# Describe resource
kubectl describe pod <pod-name> -n dev
kubectl describe svc <service-name> -n dev

# View logs
kubectl logs <pod-name> -n dev
kubectl logs -f <pod-name> -n dev           # Follow logs
kubectl logs <pod-name> -n dev --previous   # Previous container

# Port forward
kubectl port-forward svc/frontend-api 8080:80 -n dev

# Scale deployment
kubectl scale deployment frontend-api --replicas=3 -n dev

# Restart deployment
kubectl rollout restart deployment frontend-api -n dev

# Delete pod (forces recreation)
kubectl delete pod <pod-name> -n dev
```

### Helm Commands

```powershell
# List releases
helm list -n dev
helm list -A                    # All namespaces

# Get release info
helm get all frontend-api -n dev
helm get values frontend-api -n dev
helm history frontend-api -n dev

# Upgrade release
helm upgrade frontend-api ./shared/helm-charts/plain-app-chart `
  --set image.tag=20250115.1 `
  --namespace dev

# Rollback
helm rollback frontend-api -n dev       # Previous version
helm rollback frontend-api 3 -n dev     # Specific revision

# Uninstall
helm uninstall frontend-api -n dev
```

### Azure CLI Commands

```powershell
# AKS commands
az aks list --output table
az aks show --resource-group $RESOURCE_GROUP --name $AKS_NAME
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME

# ACR commands
az acr list --output table
az acr repository list --name $ACR_NAME --output table
az acr repository show-tags --name $ACR_NAME --repository frontend-api

# Check ACR integration
az aks check-acr --resource-group $RESOURCE_GROUP --name $AKS_NAME --acr $ACR_URL

# Attach ACR to AKS
az aks update -n $AKS_NAME -g $RESOURCE_GROUP --attach-acr $ACR_NAME
```

### Docker Commands

```powershell
# Build image
docker build -t frontend-api:local .
docker build -f Dockerfile -t frontend-api:local .

# Run container
docker run -p 8080:8080 frontend-api:local
docker run -p 8080:8080 -e ASPNETCORE_ENVIRONMENT=Development frontend-api:local

# View logs
docker logs <container-id>
docker logs -f <container-id>

# List containers
docker ps                       # Running containers
docker ps -a                    # All containers

# Remove containers
docker rm <container-id>
docker rm -f <container-id>     # Force remove

# List images
docker images

# Remove images
docker rmi frontend-api:local
```

### .NET Commands

```powershell
# Create projects
dotnet new webapi -n MyService
dotnet new xunit -n MyService.Tests
dotnet new sln -n MyService

# Build and run
dotnet restore
dotnet build
dotnet run
dotnet test

# Add packages
dotnet add package Microsoft.EntityFrameworkCore
dotnet add package Swashbuckle.AspNetCore

# Publish
dotnet publish -c Release -o ./publish
```

---

## Next Steps

### 1. Add More Services

Follow the [Adding New Services](#adding-new-services) section to add your remaining 48+ services.

### 2. Implement Monitoring

- **Azure Monitor** for AKS cluster metrics
- **Application Insights** for .NET application telemetry
- **Prometheus + Grafana** for custom metrics
- **Centralized logging** with ELK or Azure Log Analytics

### 3. Enhance Security

- **Azure Key Vault** integration for secrets
- **Network policies** in Kubernetes
- **Pod security policies**
- **RBAC** refinement
- **Container image scanning**

### 4. Optimize Performance

- **Horizontal Pod Autoscaling (HPA)**
- **Cluster autoscaling**
- **Resource optimization** (right-size pods)
- **Caching strategies**

### 5. Advanced Features

- **API Gateway** (Azure API Management or Kong)
- **Service Mesh** (Istio or Linkerd)
- **Advanced networking** (Ingress controllers)
- **Database integration** (Azure SQL, Cosmos DB)

---

## Summary

You've successfully set up:

✅ Azure infrastructure (AKS + ACR)  
✅ Azure DevOps (pipelines, connections, environments)  
✅ Monorepo with shared templates  
✅ GitFlow deployment strategy  
✅ Sample services deployed  
✅ Production approval gates  

**Your platform is now ready for 50+ microservices!**

---

## Need Help?

**Common Issues:** See [Troubleshooting](#troubleshooting)  
**Commands:** See [Command Reference](#command-reference)  
**Architecture:** See main [README.md](README.md)  

**Verification Checklist:**
```powershell
# Run this to verify everything is working
kubectl get nodes
kubectl get namespaces
kubectl get pods -n dev
helm list -n dev
az acr repository list --name $ACR_NAME --output table
```

**🎉 Happy deploying!**
