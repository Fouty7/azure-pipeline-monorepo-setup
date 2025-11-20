# RIIC Deployment Setup Guide
## Deploy backend-api and frontend-api to RIIC Environment

This guide walks you through deploying your 2 microservices (`backend-api` and `frontend-api`) to the RIIC client environment.

---

## 📋 Prerequisites

Before starting, ensure you have:
- ✅ Service Principal created (from `cross-cloud-setup.sh`)
- ✅ Access to RIIC AKS cluster (Azure US Government Cloud)
- ✅ Access to Azure DevOps with permissions to create pipelines
- ✅ Docker images built and pushed to ACR
- ✅ Helm charts ready (we'll use `plain-app-chart`)

---

## 🎯 Overview of Steps

1. **Get Image Tags** - Find the versions to deploy
2. **Create Manifest** - Define what to deploy
3. **Create Branch** - Set up `riic-environment` branch
4. **Setup Azure DevOps** - Create connections and pipeline
5. **Deploy** - Push to trigger deployment
6. **Verify** - Check deployment status

---

## Step 1: Get Your Image Tags

First, find out what image versions you want to deploy.

### Option A: From Azure DevOps Build
1. Go to your Azure DevOps project
2. Navigate to **Pipelines** → **Pipelines**
3. Find successful builds for `backend-api` and `frontend-api`
4. Note the **Build Number** (e.g., `20251120.5`)

### Option B: From ACR
```bash
# Login to Azure
az login

# List backend-api images
az acr repository show-tags --name mycaimicroervices-enb0gmcyhmgbc5ck --repository dev/mycai/services/backend-api --orderby time_desc --top 5

# List frontend-api images
az acr repository show-tags --name mycaimicroervices-enb0gmcyhmgbc5ck --repository dev/mycai/services/frontend-api --orderby time_desc --top 5
```

**Write down the tags you want:**
- backend-api: `_____________`
- frontend-api: `_____________`

---

## Step 2: Create the RIIC Manifest

Edit the manifest file with your specific details:

**File:** `manifests/riic-release-1.0.yaml`

```yaml
# RIIC Client Deployment Manifest
release:
  name: "riic-v1.0"
  environment: "riic"
  description: "Initial RIIC production release"
  
services:
  # Backend API Microservice
  - name: "backend-api"
    enabled: true
    image:
      repository: "mycaimicroervices-enb0gmcyhmgbc5ck.azurecr.io/dev/mycai/services/backend-api"
      tag: "20251120.5"  # ← CHANGE THIS to your backend-api build number
    helm:
      chart: "./HelmCharts/HelmCharts/plain-app-chart"
      releaseName: "backend-api"
      valuesFile: "services/backend-api/values.yaml"
      namespace: "default"
  
  # Frontend API Microservice
  - name: "frontend-api"
    enabled: true
    image:
      repository: "mycaimicroervices-enb0gmcyhmgbc5ck.azurecr.io/dev/mycai/services/frontend-api"
      tag: "20251120.6"  # ← CHANGE THIS to your frontend-api build number
    helm:
      chart: "./HelmCharts/HelmCharts/plain-app-chart"
      releaseName: "frontend-api"
      valuesFile: "services/frontend-api/values.yaml"
      namespace: "default"
  
  # Redis (if needed)
  - name: "redis"
    enabled: true
    helm:
      chart: "./HelmCharts/HelmCharts/redis"
      releaseName: "redis"
      valuesFile: "./HelmCharts/HelmCharts/redis/values.yaml"
      namespace: "default"
```

**Action Items:**
- [ ] Update `backend-api` tag with your build number
- [ ] Update `frontend-api` tag with your build number
- [ ] Update ACR repository paths if different
- [ ] Check if values.yaml files exist in service directories
- [ ] Add/remove dependencies (Redis, RabbitMQ) as needed

---

## Step 3: Create riic-environment Branch

```bash
# Navigate to your repo
cd /path/to/azure-pipeline-monorepo-setup

# Create and switch to riic-environment branch
git checkout -b riic-environment

# Add the manifest file
git add manifests/riic-release-1.0.yaml

# Commit
git commit -m "Initial RIIC deployment manifest"

# Push to remote
git push -u origin riic-environment
```

---

## Step 4: Setup Azure DevOps

### 4.1 Create Kubernetes Service Connection

1. **Go to Azure DevOps** → Your Project
2. Click **Project Settings** (bottom left)
3. Navigate to **Pipelines** → **Service connections**
4. Click **New service connection**
5. Select **Kubernetes**
6. Choose **Azure Subscription** as authentication method
7. Fill in details:
   ```
   Connection name: RIIC-AKS-Connection
   Azure subscription: [Select your US Gov subscription]
   Cluster: [Select RIIC AKS cluster]
   Namespace: default
   ```
8. Click **Verify and Save**

**Alternative: Manual Kubeconfig Method**
If above doesn't work:
1. Select **Kubeconfig** authentication
2. Upload the kubeconfig file from cross-cloud setup: `kubeconfig-riic-allegro.yaml`
3. Click **Verify and Save**

---

### 4.2 Create Environment

1. In Azure DevOps, go to **Pipelines** → **Environments**
2. Click **New environment**
3. Fill in:
   ```
   Name: RIIC-Production
   Description: RIIC Client Production Environment
   Resource: None (select this option)
   ```
4. Click **Create**
5. (Optional) Add **Approvals**:
   - Click on the environment
   - Go to **Approvals and checks**
   - Add required approvers before deployment

---

### 4.3 Create the Pipeline

1. Go to **Pipelines** → **Pipelines**
2. Click **New pipeline**
3. Select **Azure Repos Git** (or your source)
4. Select your repository
5. Choose **Existing Azure Pipelines YAML file**
6. Select:
   ```
   Branch: riic-environment
   Path: /CAI-pipelines/riic-deployment-pipeline.yml
   ```
7. Click **Continue**
8. Review the pipeline
9. Click **Save** (not Run yet!)

---

### 4.4 Update Pipeline Variables

Before running, update the pipeline file if needed:

**File:** `CAI-pipelines/riic-deployment-pipeline.yml`

Find line 34 and ensure service connection name matches:
```yaml
kubernetesServiceConnection: 'RIIC-AKS-Connection'  # Must match what you created
```

Commit any changes:
```bash
git add CAI-pipelines/riic-deployment-pipeline.yml
git commit -m "Update service connection name"
git push origin riic-environment
```

---

## Step 5: Test Deployment

### 5.1 Trigger the Pipeline

**Method 1: Manual Trigger**
1. Go to **Pipelines** → **Pipelines**
2. Find "RIIC Client Deployment Pipeline"
3. Click **Run pipeline**
4. Confirm settings and click **Run**

**Method 2: Automatic Trigger**
```bash
# Make a small change to manifest
git checkout riic-environment

# Edit manifests/riic-release-1.0.yaml (change description or comment)

git add manifests/riic-release-1.0.yaml
git commit -m "Deploy backend-api and frontend-api to RIIC"
git push origin riic-environment
```

Pipeline will automatically trigger!

---

### 5.2 Monitor Deployment

1. **Watch Pipeline Progress**
   - Go to Pipelines → Your running pipeline
   - Monitor each stage:
     - ✅ Validate Manifest
     - ✅ Deploy to RIIC
     - ✅ Health Check

2. **Check Logs**
   - Click on each task to see detailed logs
   - Look for "✓" success indicators

3. **Expected Output**
   ```
   ========================================
   Deploying: backend-api
   ========================================
     Chart: ./HelmCharts/HelmCharts/plain-app-chart
     Release: backend-api
     Namespace: default
     Image: mycaimicroervices...backend-api:20251120.5
   
   → Running: helm upgrade --install backend-api...
   ✓ backend-api deployed successfully
   
   ========================================
   Deploying: frontend-api
   ========================================
   ...
   ✓ frontend-api deployed successfully
   ```

---

## Step 6: Verify Deployment

### 6.1 Check via Pipeline
The pipeline automatically runs health checks. Look for:
```
✓ All pods are running successfully!
```

### 6.2 Manual Verification

Connect to RIIC cluster:
```bash
# Use the kubeconfig from cross-cloud setup
export KUBECONFIG=kubeconfig-riic-allegro.yaml

# Check pods
kubectl get pods -n default

# Expected output:
# NAME                           READY   STATUS    RESTARTS   AGE
# backend-api-xxxxx-xxxxx        1/1     Running   0          2m
# frontend-api-xxxxx-xxxxx       1/1     Running   0          2m
# redis-xxxxx-xxxxx              1/1     Running   0          2m
```

### 6.3 Check Services
```bash
# List services
kubectl get svc -n default

# Check specific service
kubectl describe svc backend-api -n default
```

### 6.4 Check Logs
```bash
# Backend API logs
kubectl logs -l app=backend-api -n default --tail=50

# Frontend API logs
kubectl logs -l app=frontend-api -n default --tail=50
```

---

## 🔄 Deploy Updates

When you need to deploy new versions:

### Quick Update Process:
1. **Get new build numbers** from Azure DevOps
2. **Update manifest**:
   ```bash
   git checkout riic-environment
   # Edit manifests/riic-release-1.0.yaml
   # Change image tags to new build numbers
   ```
3. **Commit and push**:
   ```bash
   git add manifests/riic-release-1.0.yaml
   git commit -m "Deploy backend-api v20251121.3 and frontend-api v20251121.4"
   git push origin riic-environment
   ```
4. **Pipeline auto-triggers** and deploys new versions

---

## 🐛 Troubleshooting

### Pipeline Fails: "Service connection not found"
**Solution:** 
- Check service connection name matches in pipeline YAML (line 34)
- Verify service connection is authorized for the pipeline

### Pipeline Fails: "Unable to connect to cluster"
**Solution:**
```bash
# Test kubeconfig manually
export KUBECONFIG=kubeconfig-riic-allegro.yaml
kubectl cluster-info

# If fails, re-run cross-cloud-setup.sh
```

### Pod Shows "ImagePullBackOff"
**Solution:**
```bash
# Check service principal access
kubectl describe pod <pod-name> -n default

# Look for error like "unauthorized" or "not found"
# If unauthorized, verify service principal role assignment:
az role assignment list --assignee <sp-app-id> --scope <acr-resource-id>
```

### Pod Shows "CrashLoopBackOff"
**Solution:**
```bash
# Check pod logs
kubectl logs <pod-name> -n default

# Check if environment variables or config missing
kubectl describe pod <pod-name> -n default
```

### Values.yaml File Not Found
**Solution:**
Create values.yaml files if missing:

**File:** `services/backend-api/values.yaml`
```yaml
replicaCount: 1

image:
  repository: mycaimicroervices-enb0gmcyhmgbc5ck.azurecr.io/dev/mycai/services/backend-api
  pullPolicy: IfNotPresent
  tag: ""

imagePullSecrets:
  - name: acr-public-cloud-secret  # From cross-cloud setup

service:
  type: ClusterIP
  port: 8080

resources:
  limits:
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 256Mi
```

Repeat for `services/frontend-api/values.yaml`.

---

## 📝 Checklist

Use this checklist to track your progress:

- [ ] Got image tags for backend-api and frontend-api
- [ ] Created/Updated `manifests/riic-release-1.0.yaml`
- [ ] Created `riic-environment` branch
- [ ] Pushed manifest to `riic-environment` branch
- [ ] Created Kubernetes service connection in Azure DevOps
- [ ] Created RIIC-Production environment in Azure DevOps
- [ ] Created pipeline pointing to `riic-deployment-pipeline.yml`
- [ ] Verified service connection name in pipeline YAML
- [ ] Triggered pipeline (manual or automatic)
- [ ] Monitored pipeline execution
- [ ] Verified pods are running
- [ ] Checked service endpoints
- [ ] Tested application functionality

---

## 🎉 Success!

Once all checks pass, you've successfully deployed your microservices to RIIC!

### Next Steps:
1. **Document deployed versions** for reference
2. **Setup monitoring/alerts** in Azure
3. **Create runbook** for common operations
4. **Train team** on update process

---

## 📞 Need Help?

- Check pipeline logs first
- Review troubleshooting section above
- Verify all Azure DevOps connections
- Test kubectl access manually
- Check service principal permissions
