# Cross-Cloud Setup Script - Usage Guide

## Prerequisites

Before running the script, ensure you have:

### Required Tools
- ✅ **Azure CLI** (`az`) installed
- ✅ **kubectl** installed
- ✅ **Bash shell** (Git Bash, WSL, or Linux/macOS terminal)

### Required Information
Have the following information ready before running the script:

#### Public Cloud (Commercial Azure)
- ACR name
- ACR resource group
- Public Cloud subscription ID

#### Service Principal
- Customer ID (e.g., "customer-1")

#### US Government Cloud
- Customer's AKS cluster name
- Customer's AKS resource group
- Customer's US Gov subscription ID

#### Kubernetes Configuration
- Target namespace (optional, defaults to "default")
- Secret name (optional, defaults to "acr-public-cloud-secret")
- Test image from ACR (e.g., "nginx:latest")

## 🚀 Running the Script

### Step 1: Make the Script Executable

```bash
chmod +x cross-cloud-setup.sh
```

### Step 2: Run the Script

```bash
./cross-cloud-setup.sh
```

### Step 3: Follow Interactive Prompts

The script will guide you through 5 main sections:

1. **Prerequisites Check** - Validates required tools
2. **Configuration Input** - Collects all necessary information
3. **Public Cloud Setup** - Configures ACR and creates service principal
4. **US Government Cloud Setup** - Configures AKS cluster access
5. **Kubernetes Secret Creation** - Sets up image pull secrets
6. **Testing** - Deploys a test pod to verify connectivity

## What the Script Does

### Part 1: Public Cloud ACR Setup
- Switches to Azure Public Cloud
- Logs into your Public Cloud account
- Sets the correct subscription
- Retrieves ACR information (Resource ID and Login Server)

### Part 2: Service Principal Creation
- Creates a service principal with AcrPull role
- Saves credentials to a local file (`sp-credentials-<customer-id>.txt`)
- **IMPORTANT:** Displays credentials on screen for immediate secure storage
- Waits for Azure role assignment propagation
- Verifies role assignment

### Part 3: US Government Cloud Setup
- Switches to Azure US Government Cloud
- Logs into US Gov account (browser authentication)
- Sets the correct US Gov subscription
- Verifies AKS cluster exists
- Downloads AKS credentials to local kubeconfig file
- Tests Kubernetes connectivity

### Part 4: Kubernetes Secret Creation
- Creates namespace if it doesn't exist
- Creates docker-registry secret with service principal credentials
- Verifies secret creation

### Part 5: Testing
- Creates a test pod manifest
- Deploys test pod using the image pull secret
- Monitors pod status
- Optionally cleans up test pod

## Generated Files

After successful execution, you'll have:

1. **`sp-credentials-<customer-id>.txt`**
   - Contains service principal credentials
   - **⚠️ Store in Azure Key Vault or secure location**
   - **⚠️ Delete after storing securely**

2. **`kubeconfig-<customer-id>.yaml`**
   - Kubernetes configuration for AKS cluster
   - Use this for future kubectl commands

3. **`test-cross-cloud-access-<customer-id>.yaml`**
   - Test pod manifest
   - Can be used as a reference for future deployments

## 🔄 Using the Setup in Deployments

After successful setup, reference the secret in your Kubernetes deployments:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: default
spec:
  template:
    spec:
      imagePullSecrets:
        - name: acr-public-cloud-secret  # Use the secret name you configured
      containers:
        - name: my-app
          image: yourcompanyacr.azurecr.io/my-app:latest
```

## Troubleshooting

## Switching Between Clouds Manually

If you need to manually switch between clouds after running the script:

### Switch to Public Cloud
```bash
az cloud set --name AzureCloud
az login
az account set --subscription <public-subscription-id>
```

### Switch to US Government Cloud
```bash
az cloud set --name AzureUSGovernment
az login
az account set --subscription <usgov-subscription-id>
```

### Check Current Cloud
```bash
az cloud show --query name
`