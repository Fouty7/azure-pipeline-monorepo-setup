
## 📋 **Prerequisites**

Before starting, have ready:
- ✅ Your ACR name (Public Cloud)
- ✅ Your ACR resource group (Public Cloud)
- ✅ Your Public Cloud subscription ID
- ✅ Customer's AKS cluster name (US Gov)
- ✅ Customer's AKS resource group (US Gov)
- ✅ Customer's US Gov subscription ID
- ✅ Azure CLI installed
- ✅ kubectl installed

---

### **Step 1: Switch to Azure Public Cloud**

```bash
az cloud set --name AzureCloud
```

**Expected Output:**
```
Cloud 'AzureCloud' is now active
```

---

### **Step 2: Login to Azure Public Cloud**

```bash
az login
```
---

### **Step 3: Set Your Subscription**

```bash
# Replace with YOUR subscription ID
az account set --subscription "YOUR_PUBLIC_CLOUD_SUBSCRIPTION_ID"
```

---

### **Step 4: Get Your ACR Information**

```bash
# Replace with YOUR values
YOUR_ACR_NAME="yourcompanyacr"
YOUR_ACR_RG="your-acr-resource-group"

# Get ACR details
az acr show \
  --name $YOUR_ACR_NAME \
  --resource-group $YOUR_ACR_RG
```

**Expected Output:**
```json
{
  "id": "/subscriptions/.../resourceGroups/.../providers/Microsoft.ContainerRegistry/registries/yourcompanyacr",
  "loginServer": "yourcompanyacr.azurecr.io",
  "name": "yourcompanyacr",
  ...
}
```

**Save these values:**
- `id` = ACR Resource ID (needed later)
- `loginServer` = ACR Login Server (needed later)

---

### **Step 5: Save ACR Resource ID**

```bash
# Save the full ACR resource ID
ACR_RESOURCE_ID=$(az acr show \
  --name $YOUR_ACR_NAME \
  --resource-group $YOUR_ACR_RG \
  --query id \
  --output tsv)

# Display it
echo "ACR Resource ID: $ACR_RESOURCE_ID"
```

---

### **Step 6: Save ACR Login Server**

```bash
# Save the ACR login server
ACR_LOGIN_SERVER=$(az acr show \
  --name $YOUR_ACR_NAME \
  --resource-group $YOUR_ACR_RG \
  --query loginServer \
  --output tsv)

# Display it
echo "ACR Login Server: $ACR_LOGIN_SERVER"
```

**Expected Output:**
```
ACR Login Server: yourcompanyacr.azurecr.io
```

---

## 🔐 **PART 2: Create Service Principal (Cross-Cloud Bridge)**

### **Step 7: Create Service Principal with ACR Pull Access**

```bash
# Choose a unique name for the customer
CUSTOMER_ID="customer-1"  # riic customer
SP_NAME="sp-${CUSTOMER_ID}-acr-pull"

# Create service principal with AcrPull role
az ad sp create-for-rbac \
  --name $SP_NAME \
  --role "AcrPull" \
  --scopes $ACR_RESOURCE_ID
```

**Expected Output:**
```json
{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "displayName": "sp-customer-1-acr-pull",
  "password": "super-secret-password-here",
  "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

**⚠️ IMPORTANT: SAVE THESE VALUES IMMEDIATELY!**

---

### **Step 8: Save Service Principal Credentials**

```bash
# Copy the values from Step 7 output

SP_APP_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"     # Copy from appId
SP_PASSWORD="super-secret-password-here"              # Copy from password
SP_TENANT="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"    # Copy from tenant

# Display to verify
echo "Service Principal App ID: $SP_APP_ID"
echo "Service Principal Password: $SP_PASSWORD"
echo "Service Principal Tenant: $SP_TENANT"
```

**⚠️ Store these somewhere safe (Password manager, Azure Key Vault, etc.)**

---

### **Step 9: Verify Role Assignment**

```bash
# Wait for Azure to propagate the role (important!)
echo "Waiting 30 seconds for role assignment to propagate..."
sleep 30

# Verify the role assignment
az role assignment list \
  --assignee $SP_APP_ID \
  --scope $ACR_RESOURCE_ID \
  --output table
```

**Expected Output:**
```
Principal                             Role     Scope
------------------------------------  -------  ------------------------------------------
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx  AcrPull  /subscriptions/.../yourcompanyacr
```
---

## 🇺🇸 **PART 3: Setup Customer's AKS (US Government Cloud)**

### **Step 10: Switch to Azure US Government Cloud**

```bash
az cloud set --name AzureUSGovernment
```

**Expected Output:**
```
Cloud 'AzureUSGovernment' is now active
```

---

### **Step 11: Login to Azure US Government**

```bash
az login
```

**What to do:**
- Browser opens to US Government login portal
- Login with customer's credentials (or yours if you have access)
- Close browser when done

**Expected Output:**
```
[
  {
    "cloudName": "AzureUSGovernment",
    "id": "customer-subscription-id",
    "name": "Customer Subscription Name",
    ...
  }
]
```

---

### **Step 12: Set Customer's Subscription**

```bash
# Replace with CUSTOMER'S US Gov subscription ID
CUSTOMER_SUBSCRIPTION_ID="customer-usgov-subscription-id"

az account set --subscription $CUSTOMER_SUBSCRIPTION_ID
```

---

### **Step 13: Verify Customer's AKS Cluster**

```bash
# Replace with customer's values
CUSTOMER_AKS_NAME="customer-aks-cluster"
CUSTOMER_AKS_RG="customer-aks-rg"

# Verify cluster exists
az aks show \
  --resource-group $CUSTOMER_AKS_RG \
  --name $CUSTOMER_AKS_NAME \
  --query "{name:name, location:location, provisioningState:provisioningState}" \
  --output table
```

**Expected Output:**
```
Name                  Location      ProvisioningState
--------------------  ------------  -------------------
customer-aks-cluster  usgovvirginia Succeeded
```

---

### **Step 14: Get AKS Credentials**

```bash
# Download kubeconfig
az aks get-credentials \
  --resource-group $CUSTOMER_AKS_RG \
  --name $CUSTOMER_AKS_NAME \
  --file kubeconfig-$CUSTOMER_ID.yaml \
  --overwrite-existing

# Set KUBECONFIG environment variable
export KUBECONFIG="kubeconfig-$CUSTOMER_ID.yaml"

# Display the file location
echo "Kubeconfig saved to: kubeconfig-$CUSTOMER_ID.yaml"
```

**Expected Output:**
```
Merged "customer-aks-cluster" as current context in kubeconfig-customer-1.yaml
Kubeconfig saved to: kubeconfig-customer-1.yaml
```

---

### **Step 15: Test Kubernetes Connection**

```bash
# Test connection
kubectl cluster-info
```

**Expected Output:**
```
Kubernetes control plane is running at https://customer-aks-xxxxx.usgovcloudapi.net:443
CoreDNS is running at https://customer-aks-xxxxx.usgovcloudapi.net:443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

---

## 🔑 **PART 4: Create Kubernetes Secret**

### **Step 16: Create Image Pull Secret**

```bash
# Set namespace (change if deploying to different namespace)
NAMESPACE="default"
SECRET_NAME="acr-public-cloud-secret"

# Create the secret (uses variables from Step 8)
kubectl create secret docker-registry $SECRET_NAME \
  --namespace $NAMESPACE \
  --docker-server=$ACR_LOGIN_SERVER \
  --docker-username=$SP_APP_ID \
  --docker-password=$SP_PASSWORD
```

**Expected Output:**
```
secret/acr-public-cloud-secret created
```

---

### **Step 17: Verify Secret Was Created**

```bash
# List secrets
kubectl get secret $SECRET_NAME -n $NAMESPACE
```

**Expected Output:**
```
NAME                      TYPE                             DATA   AGE
acr-public-cloud-secret   kubernetes.io/dockerconfigjson   1      5s
```

---


---

### **Step 19: Create Test Pod**

```bash
# Create test manifest
cat > test-cross-cloud-access.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: acr-test-pod
  namespace: $NAMESPACE
spec:
  imagePullSecrets:
    - name: $SECRET_NAME
  containers:
    - name: test
      image: $ACR_LOGIN_SERVER/nginx:latest #Make sure image exists in your acr
      ports:
        - containerPort: 80
  restartPolicy: Never
EOF

# Display the file
cat test-cross-cloud-access.yaml
```

---

### **Step 20: Deploy Test Pod**

```bash
# Apply the manifest
kubectl apply -f test-cross-cloud-access.yaml
```

**Expected Output:**
```
pod/acr-test-pod created
```

---

### **Step 21: Check Pod Status**

```bash
# Wait a few seconds, then check status
sleep 10

kubectl get pod acr-test-pod -n $NAMESPACE
```

**Expected Output (Success):**
```
NAME           READY   STATUS    RESTARTS   AGE
acr-test-pod   1/1     Running   0          15s
```

**If you see `ImagePullBackOff` or `ErrImagePull`:**
```
NAME           READY   STATUS             RESTARTS   AGE
acr-test-pod   0/1     ImagePullBackOff   0          30s
```

---

### **Step 22: Troubleshoot if Needed**

```bash
# Get detailed pod information
kubectl describe pod acr-test-pod -n $NAMESPACE
```

**Look for these sections in the output:**

**Success looks like:**
```
Events:
  Type    Reason     Message
  ----    ------     -------
  Normal  Pulling    Pulling image "yourcompanyacr.azurecr.io/nginx:latest"
  Normal  Pulled     Successfully pulled image
  Normal  Created    Created container test
  Normal  Started    Started container test
```

**Failure looks like:**
```
Events:
  Type     Reason     Message
  ----     ------     -------
  Normal   Pulling    Pulling image "yourcompanyacr.azurecr.io/nginx:latest"
  Warning  Failed     Failed to pull image: unauthorized
```

---

### **Step 23: Clean Up Test Pod**

```bash
# Delete test pod
kubectl delete pod acr-test-pod -n $NAMESPACE
```

**Expected Output:**
```
pod "acr-test-pod" deleted
```

---
