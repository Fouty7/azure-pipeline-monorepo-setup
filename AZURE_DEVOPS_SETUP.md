# Azure DevOps Configuration Guide

This guide explains the manual setup required in Azure DevOps to make the pipeline work.

## 1. Service Connections

Service connections must be created in Azure DevOps Project Settings.

### Kubernetes Service Connections

Create 4 Kubernetes service connections:

1. **aks-dev-connection**
   - Name: `aks-dev-connection`
   - Cluster URL: `https://<your-dev-aks-cluster-url>`
   - Kubeconfig or Service Account credentials for dev cluster

2. **aks-qa-connection**
   - Name: `aks-qa-connection`
   - Cluster URL: `https://<your-qa-aks-cluster-url>`
   - Kubeconfig or Service Account credentials for QA cluster

3. **aks-staging-connection**
   - Name: `aks-staging-connection`
   - Cluster URL: `https://<your-staging-aks-cluster-url>`
   - Kubeconfig or Service Account credentials for staging cluster

4. **aks-prod-connection**
   - Name: `aks-prod-connection`
   - Cluster URL: `https://<your-prod-aks-cluster-url>`
   - Kubeconfig or Service Account credentials for production cluster

**Steps to create:**
1. Go to Project Settings → Pipelines → Service connections
2. Click "New service connection"
3. Select "Kubernetes"
4. Enter cluster details
5. Name it exactly as listed above

### Azure Container Registry (ACR) Service Connection

Create one ACR service connection:

1. **my-acr-connection**
   - Name: `my-acr-connection`
   - Registry URL: `https://<your-registry>.azurecr.io`
   - Azure subscription connection

**Steps to create:**
1. Go to Project Settings → Pipelines → Service connections
2. Click "New service connection"
3. Select "Docker Registry"
4. Authentication type: Azure Container Registry
5. Select your subscription and registry
6. Name it: `my-acr-connection`

---

## 2. Secure Files (Optional - for non-dev environments)

If you want to use environment-specific Helm values files:

### What are Secure Files?

Secure files are encrypted files stored in Azure Pipelines Library that contain sensitive configuration.

### Create Secure Files

For QA, Staging, and Production environments:

1. **frontend-api-qa-values.yml**
   - Go to Pipelines → Library → Secure files
   - Upload your QA Helm values file
   - Name: `frontend-api-qa-values.yml`

2. **frontend-api-staging-values.yml**
   - Upload your staging Helm values file
   - Name: `frontend-api-staging-values.yml`

3. **frontend-api-prod-values.yml**
   - Upload your production Helm values file
   - Name: `frontend-api-prod-values.yml`

Similarly for backend-api:
- `backend-api-qa-values.yml`
- `backend-api-staging-values.yml`
- `backend-api-prod-values.yml`

**File Format Example (YAML):**
```yaml
# frontend-api-qa-values.yml
replicaCount: 2
image:
  pullPolicy: IfNotPresent
resources:
  limits:
    cpu: 500m
    memory: 512Mi
```

**Steps to upload:**
1. Go to Pipelines → Library → Secure files
2. Click "+ Secure file"
3. Upload your YAML file
4. Name it exactly as listed above
5. Click "Save"

---

## 3. Environments (Optional - for production approval)

Azure Pipelines Environments enable approval gates.

### Create Environments

1. **dev**
   - Go to Pipelines → Environments
   - Click "Create environment"
   - Name: `dev`
   - No approvers needed

2. **qa**
   - Name: `qa`
   - No approvers needed

3. **staging**
   - Name: `staging`
   - No approvers needed

4. **prod** (with approval)
   - Name: `prod`
   - Click on environment
   - Go to Approvals and checks
   - Add an approval check
   - Select users who must approve production deployments

---

## 4. Variables (Update in Pipeline Files)

Update these in `azure-pipeline.yml` for each service:

### For frontend-api

Edit `services/frontend-api/azure-pipeline.yml`:

```yaml
variables:
  acrUrl: 'YOUR_ACR_URL.azurecr.io'  # e.g., mytestacr690.azurecr.io
  acrServiceConnection: 'YOUR_ACR_CONNECTION_NAME'  # e.g., my-acr-connection
```

And for each k8sServiceConnection:
```yaml
k8sServiceConnection: 'aks-dev-connection'  # UPDATE THIS - should match your service connection name
```

### For backend-api

Edit `services/backend-api/azure-pipeline.yml`:

Same variables as frontend-api.

---

## 5. Checklist

Before running the pipeline, verify:

- [ ] Created 4 Kubernetes service connections (dev, qa, staging, prod)
- [ ] Created 1 ACR service connection
- [ ] Updated `acrUrl` in both pipeline files
- [ ] Updated `acrServiceConnection` name in both pipeline files
- [ ] Updated K8S connection names to match your service connections
- [ ] (Optional) Created secure files for QA, Staging, Prod Helm values
- [ ] (Optional) Created environments with prod approval gate
- [ ] All service connections are authorized for your pipeline

---

## 6. Testing the Pipeline

### Test PR Validation

```bash
git checkout -b feature/test-pr
# Make a small code change
git push origin feature/test-pr
# Create PR to dev
# Watch pipeline validate
```

### Test Deployment

```bash
# After PR is merged to dev
# Watch Build → Docker → Helm Deploy stages
```

### Test Production Approval

```bash
# Create PR from staging to main
# Merge to main
# Pipeline pauses at "Approval Gate - Production Deployment"
# Approve in Azure DevOps UI
# Deployment proceeds
```

---

## 7. Troubleshooting

### Service Connection Not Found

**Error:** "could not be found. The service connection does not exist..."

**Solution:** 
- Check the service connection name matches exactly
- Verify service connection exists in Project Settings
- Ensure it's authorized for your pipeline

### Secure File Not Found

**Error:** "secure file XXX which could not be found..."

**Solution:**
- Check the secure file name matches exactly
- Verify file exists in Pipelines → Library → Secure files
- For dev environment: this error is OK, no secure file is needed

### Kubernetes Connection Fails

**Error:** "could not find a resource with name..."

**Solution:**
- Verify cluster URL is correct
- Check service account has permissions
- Ensure kubeconfig is valid
- Test connection in Azure DevOps UI

---

## 8. Next Steps

1. Complete all configuration above
2. Create a test PR to validate the setup
3. Monitor the pipeline execution
4. Fix any authorization or configuration issues
5. Once working, integrate with your CI/CD workflow
