# RIIC Deployment Manifests

## 📖 Overview

This directory contains deployment manifests for client environments. A manifest is a single file that defines what services and versions to deploy.

## 🚀 How to Deploy to RIIC

### Simple 3-Step Process:

1. **Update the manifest file** (`riic-release-1.0.yaml`)
   - Change image tags to the versions you want to deploy
   - Enable/disable services as needed

2. **Commit and push to `riic-environment` branch**
   ```bash
   git checkout riic-environment
   git add manifests/riic-release-1.0.yaml
   git commit -m "Deploy version X.Y to RIIC"
   git push origin riic-environment
   ```

3. **Pipeline automatically deploys**
   - Pipeline triggers automatically
   - Validates manifest
   - Deploys all enabled services
   - Runs health checks

## 📝 Manifest File Structure

### Example Service (Microservice with Image):
```yaml
- name: "my-api"
  enabled: true  # Set to false to skip
  image:
    repository: "myacr.azurecr.io/dev/my-api"
    tag: "20251120.5"  # Change this to deploy new version
  helm:
    chart: "./HelmCharts/HelmCharts/plain-app-chart"
    releaseName: "my-api"
    valuesFile: "Apps/MyApi/values.yaml"
    namespace: "default"
```

### Example Dependency (No Image - Uses Chart Default):
```yaml
- name: "redis"
  enabled: true
  helm:
    chart: "./HelmCharts/HelmCharts/redis"
    releaseName: "redis"
    valuesFile: "./HelmCharts/HelmCharts/redis/values.yaml"
    namespace: "default"
```

## 🔄 Common Tasks

### Deploy a New Version
1. Find the service in `riic-release-1.0.yaml`
2. Update the `tag` field:
   ```yaml
   tag: "20251120.10"  # New version
   ```
3. Commit and push to `riic-environment` branch

### Disable a Service Temporarily
```yaml
- name: "optional-service"
  enabled: false  # Won't be deployed
```

### Deploy Only Specific Services
Set `enabled: false` for services you don't want:
```yaml
services:
  - name: "service-1"
    enabled: true   # ✓ Will deploy
  
  - name: "service-2"
    enabled: false  # ✗ Will skip
```

## 🛠️ Manual Deployment (Without Pipeline)

If you need to deploy manually:

```bash
# Make script executable
chmod +x scripts/deploy-manifest.sh

# Deploy
./scripts/deploy-manifest.sh manifests/riic-release-1.0.yaml default
```

## 📋 Finding Image Tags

To find what versions are in Prod:

```bash
# List all pods in prod namespace
kubectl get pods -n prod -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'
```

Or check Azure DevOps build numbers from successful Prod deployments.

## 🔍 Troubleshooting

### Pipeline Fails at Validation
- Check YAML syntax in manifest file
- Ensure all required fields are present
- Run locally: `yq eval '.' manifests/riic-release-1.0.yaml`

### Service Won't Deploy
- Verify image tag exists in ACR
- Check service principal has pull access
- Verify Helm chart path is correct
- Check values file exists

### Pod Not Starting
```bash
# Check pod status
kubectl get pods -n default

# Get detailed info
kubectl describe pod <pod-name> -n default

# Check logs
kubectl logs <pod-name> -n default
```

## 📁 Creating New Manifests

For a new client or release:

```bash
# Copy existing manifest
cp riic-release-1.0.yaml riic-release-2.0.yaml

# Update release info
# Edit the 'release' section at the top
```

## ⚙️ Azure DevOps Setup Required

Before the pipeline works, set up in Azure DevOps:

1. **Create Kubernetes Service Connection**
   - Name: `RIIC-AKS-Connection`
   - Points to RIIC AKS cluster
   - Uses service principal credentials

2. **Create Environment**
   - Name: `RIIC-Production`
   - Add approvals if needed

3. **Create Pipeline**
   - Point to `CAI-pipelines/riic-deployment-pipeline.yml`
   - Ensure it triggers on `riic-environment` branch

## 🎯 Best Practices

1. **Always test in Dev/Test first** before updating RIIC manifest
2. **Use descriptive commit messages** - they appear in deployment history
3. **Deploy during maintenance windows** for major changes
4. **Keep old manifest versions** for easy rollback
5. **Document version changes** in release notes

## 🔐 Security Notes

- Never commit secrets or passwords in manifest files
- Use `secureValuesFile` for sensitive configuration
- Store secure files in Azure DevOps Library
- Service principal credentials managed by Azure DevOps
