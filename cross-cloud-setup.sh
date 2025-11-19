#!/bin/bash

#===============================================================================
# Cross-Cloud Azure Setup Script
# Purpose: Automate ACR (Public Cloud) to AKS (US Gov Cloud) connectivity
#===============================================================================

set -e  # Exit on any error

# Color codes for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local missing_tools=()
    
    if ! command -v az &> /dev/null; then
        missing_tools+=("Azure CLI (az)")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools:"
        for tool in "${missing_tools[@]}"; do
            echo "  - $tool"
        done
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Get user input
get_user_input() {
    print_header "Configuration Setup"
    
    echo -e "${YELLOW}Please provide the following information:${NC}\n"
    
    # Public Cloud Configuration
    print_info "PUBLIC CLOUD (Commercial Azure) Configuration:"
    read -p "Enter your ACR name: " ACR_NAME
    read -p "Enter your ACR resource group: " ACR_RG
    read -p "Enter your Public Cloud subscription ID: " PUBLIC_SUB_ID
    
    echo ""
    
    # Customer/Service Principal Configuration
    print_info "Service Principal Configuration:"
    read -p "Enter customer ID (e.g., customer-1): " CUSTOMER_ID
    SP_NAME="sp-${CUSTOMER_ID}-acr-pull"
    echo "Service Principal name will be: $SP_NAME"
    
    echo ""
    
    # US Gov Cloud Configuration
    print_info "US GOVERNMENT CLOUD Configuration:"
    read -p "Enter customer's AKS cluster name: " AKS_NAME
    read -p "Enter customer's AKS resource group: " AKS_RG
    read -p "Enter customer's US Gov subscription ID: " USGOV_SUB_ID
    
    echo ""
    
    # Kubernetes Configuration
    print_info "Kubernetes Configuration:"
    read -p "Enter namespace for deployment (default: default): " NAMESPACE
    NAMESPACE=${NAMESPACE:-default}
    read -p "Enter secret name (default: acr-public-cloud-secret): " SECRET_NAME
    SECRET_NAME=${SECRET_NAME:-acr-public-cloud-secret}
    
    echo ""
    
    # Test Configuration
    print_info "Test Configuration:"
    read -p "Enter ACR image to test (e.g., nginx:latest): " TEST_IMAGE
    TEST_IMAGE=${TEST_IMAGE:-nginx:latest}
    
    echo ""
    
    # Confirmation
    print_header "Configuration Summary"
    echo "Public Cloud ACR: $ACR_NAME"
    echo "ACR Resource Group: $ACR_RG"
    echo "Public Subscription: $PUBLIC_SUB_ID"
    echo "Customer ID: $CUSTOMER_ID"
    echo "Service Principal: $SP_NAME"
    echo "US Gov AKS Cluster: $AKS_NAME"
    echo "AKS Resource Group: $AKS_RG"
    echo "US Gov Subscription: $USGOV_SUB_ID"
    echo "Kubernetes Namespace: $NAMESPACE"
    echo "Secret Name: $SECRET_NAME"
    echo "Test Image: $TEST_IMAGE"
    
    echo ""
    read -p "Is this information correct? (yes/no): " CONFIRM
    
    if [[ ! "$CONFIRM" =~ ^[Yy][Ee][Ss]$ ]]; then
        print_error "Setup cancelled by user"
        exit 0
    fi
}

# Part 1: Setup Public Cloud ACR
setup_public_cloud() {
    print_header "PART 1: Public Cloud ACR Setup"
    
    print_info "Switching to Azure Public Cloud..."
    az cloud set --name AzureCloud
    print_success "Switched to AzureCloud"
    
    print_info "Logging into Azure Public Cloud..."
    az login
    print_success "Logged into Public Cloud"
    
    print_info "Setting subscription: $PUBLIC_SUB_ID"
    az account set --subscription "$PUBLIC_SUB_ID"
    print_success "Subscription set"
    
    print_info "Retrieving ACR information..."
    ACR_RESOURCE_ID=$(az acr show \
        --name "$ACR_NAME" \
        --resource-group "$ACR_RG" \
        --query id \
        --output tsv)
    
    if [ -z "$ACR_RESOURCE_ID" ]; then
        print_error "Failed to retrieve ACR Resource ID"
        exit 1
    fi
    
    ACR_LOGIN_SERVER=$(az acr show \
        --name "$ACR_NAME" \
        --resource-group "$ACR_RG" \
        --query loginServer \
        --output tsv)
    
    if [ -z "$ACR_LOGIN_SERVER" ]; then
        print_error "Failed to retrieve ACR Login Server"
        exit 1
    fi
    
    print_success "ACR Resource ID: $ACR_RESOURCE_ID"
    print_success "ACR Login Server: $ACR_LOGIN_SERVER"
}

# Part 2: Create Service Principal
create_service_principal() {
    print_header "PART 2: Create Service Principal"
    
    # Check if service principal already exists
    print_info "Checking for existing service principal: $SP_NAME"
    EXISTING_SP_ID=$(az ad sp list --display-name "$SP_NAME" --query '[0].appId' -o tsv 2>/dev/null | tr -d '\r\n' | xargs)
    
    if [ -n "$EXISTING_SP_ID" ] && [ "$EXISTING_SP_ID" != "null" ]; then
        print_warning "Service principal '$SP_NAME' already exists (App ID: $EXISTING_SP_ID)"
        echo ""
        read -p "Do you want to (1) Delete and recreate, (2) Reset credentials, or (3) Cancel? [1/2/3]: " SP_CHOICE
        
        case $SP_CHOICE in
            1)
                print_info "Deleting existing service principal..."
                az ad sp delete --id "$EXISTING_SP_ID"
                print_success "Service principal deleted"
                
                # Also delete the application registration
                print_info "Deleting associated application registration..."
                az ad app delete --id "$EXISTING_SP_ID" 2>/dev/null || true
                print_success "Application registration deleted"
                
                print_info "Waiting 15 seconds for deletion to propagate..."
                sleep 15
                ;;
            2)
                print_info "Resetting credentials for existing service principal..."
                SP_OUTPUT=$(az ad sp credential reset --id "$EXISTING_SP_ID" 2>&1)
                SP_EXIT_CODE=$?
                
                if [ $SP_EXIT_CODE -eq 0 ]; then
                    print_success "Credentials reset successfully!"
                    # Parse the output and skip to credentials display
                    parse_sp_credentials
                    display_sp_credentials
                    verify_role_assignment
                    return 0
                else
                    print_error "Failed to reset credentials"
                    echo "$SP_OUTPUT"
                    exit 1
                fi
                ;;
            3)
                print_error "Setup cancelled by user"
                exit 0
                ;;
            *)
                print_error "Invalid choice. Exiting."
                exit 1
                ;;
        esac
    fi
    
    print_info "Creating service principal: $SP_NAME"
    print_warning "IMPORTANT: Save the output credentials securely!"
    echo ""
    
    # Temporarily disable exit on error for this section
    set +e
    
    # Create service principal WITHOUT role (to avoid Bad Request error)
    # We'll assign the role separately afterward
    print_info "Creating service principal (without role assignment)..."
    SP_OUTPUT=$(az ad sp create-for-rbac \
        --name "$SP_NAME" \
        --skip-assignment 2>&1)
    
    SP_EXIT_CODE=$?
    
    # Re-enable exit on error
    set -e
    
    if [ $SP_EXIT_CODE -ne 0 ]; then
        print_error "Failed to create service principal (Exit Code: $SP_EXIT_CODE)"
        echo ""
        echo "Error Output:"
        echo "$SP_OUTPUT"
        echo ""
        
        # Check if there's an existing application (even though our initial check didn't find it)
        if echo "$SP_OUTPUT" | grep -qi "existing application instance"; then
            FOUND_APP_ID=$(echo "$SP_OUTPUT" | grep -oP '\(id\)\s*\K[a-f0-9-]{36}' | tr -d '\r\n' | xargs)
            if [ -n "$FOUND_APP_ID" ]; then
                print_warning "Found existing application: $FOUND_APP_ID"
                print_info "Deleting the orphaned application registration..."
                
                # Delete both SP and app registration
                az ad sp delete --id "$FOUND_APP_ID" 2>/dev/null || true
                az ad app delete --id "$FOUND_APP_ID" 2>/dev/null || true
                
                print_success "Deleted existing application"
                print_info "Waiting 15 seconds and retrying..."
                sleep 15
                
                # Retry creation
                print_info "Retrying service principal creation..."
                SP_OUTPUT=$(az ad sp create-for-rbac \
                    --name "$SP_NAME" \
                    --skip-assignment 2>&1)
                
                SP_EXIT_CODE=$?
                
                if [ $SP_EXIT_CODE -ne 0 ]; then
                    print_error "Retry failed. Please run script again or create manually."
                    echo "$SP_OUTPUT"
                    exit 1
                fi
                
                print_success "Service principal created on retry!"
            else
                exit 1
            fi
        else
            exit 1
        fi
    fi
    
    parse_sp_credentials
    display_sp_credentials
    verify_role_assignment
}

# Parse service principal credentials from output
parse_sp_credentials() {
    # Extract only the JSON part (skip WARNING lines)
    SP_JSON=$(echo "$SP_OUTPUT" | sed -n '/{/,$ p')
    
    # Disable exit on error temporarily
    set +e
    
    # Parse credentials using Python (most reliable cross-platform method)
    if command -v python3 &> /dev/null; then
        SP_APP_ID=$(echo "$SP_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin)['appId'])" 2>&1)
        PARSE_EXIT=$?
        if [ $PARSE_EXIT -ne 0 ]; then
            print_error "Failed to parse credentials using python3"
            echo "Error: $SP_APP_ID"
        fi
        SP_PASSWORD=$(echo "$SP_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin)['password'])" 2>&1)
        SP_TENANT=$(echo "$SP_JSON" | python3 -c "import sys, json; print(json.load(sys.stdin)['tenant'])" 2>&1)
    elif command -v python &> /dev/null; then
        SP_APP_ID=$(echo "$SP_JSON" | python -c "import sys, json; print(json.load(sys.stdin)['appId'])" 2>&1)
        SP_PASSWORD=$(echo "$SP_JSON" | python -c "import sys, json; print(json.load(sys.stdin)['password'])" 2>&1)
        SP_TENANT=$(echo "$SP_JSON" | python -c "import sys, json; print(json.load(sys.stdin)['tenant'])" 2>&1)
    elif command -v jq &> /dev/null; then
        SP_APP_ID=$(echo "$SP_JSON" | jq -r '.appId')
        SP_PASSWORD=$(echo "$SP_JSON" | jq -r '.password')
        SP_TENANT=$(echo "$SP_JSON" | jq -r '.tenant')
    else
        # Sed fallback - extract from full output since it doesn't care about JSON format
        SP_APP_ID=$(echo "$SP_OUTPUT" | sed -n 's/.*"appId"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
        SP_PASSWORD=$(echo "$SP_OUTPUT" | sed -n 's/.*"password"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
        SP_TENANT=$(echo "$SP_OUTPUT" | sed -n 's/.*"tenant"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    fi
    
    # Re-enable exit on error
    set -e
    
    if [ -z "$SP_APP_ID" ] || [ -z "$SP_PASSWORD" ] || [ -z "$SP_TENANT" ]; then
        print_error "Failed to parse service principal credentials"
        echo ""
        echo "Azure CLI output:"
        echo "$SP_OUTPUT"
        echo ""
        print_error "Unable to extract credentials. Please check the output above."
        exit 1
    fi
}

# Display service principal credentials
display_sp_credentials() {
    print_success "Service Principal ready!"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}SAVE THESE CREDENTIALS SECURELY:${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "App ID:    $SP_APP_ID"
    echo "Password:  $SP_PASSWORD"
    echo "Tenant:    $SP_TENANT"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Save to file
    CREDS_FILE="sp-credentials-${CUSTOMER_ID}.txt"
    cat > "$CREDS_FILE" <<EOF
Service Principal Credentials for Customer: $CUSTOMER_ID
Created: $(date)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
App ID:    $SP_APP_ID
Password:  $SP_PASSWORD
Tenant:    $SP_TENANT
ACR Login: $ACR_LOGIN_SERVER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  KEEP THIS FILE SECURE AND DELETE AFTER STORING IN SECURE LOCATION
EOF
    
    print_warning "Credentials saved to: $CREDS_FILE"
    print_warning "Store in secure location (Key Vault) and delete this file!"
    
    echo ""
    read -p "Press Enter to continue after saving credentials..."
}

# Verify role assignment
verify_role_assignment() {
    print_info "Waiting 30 seconds for role assignment to propagate..."
    sleep 30
    
    print_info "Verifying role assignment..."
    
    # Disable exit on error
    set +e
    
    # Check if role assignment exists
    ROLE_COUNT=$(az role assignment list \
        --assignee "$SP_APP_ID" \
        --scope "$ACR_RESOURCE_ID" \
        --query "length(@)" \
        --output tsv 2>&1)
    
    ROLE_CHECK_EXIT=$?
    
    if [ $ROLE_CHECK_EXIT -ne 0 ]; then
        print_warning "Unable to check existing role assignments"
    fi
    
    # Re-enable exit on error
    set -e
    
    if [ -z "$ROLE_COUNT" ] || [ "$ROLE_COUNT" -eq 0 ] || [ $ROLE_CHECK_EXIT -ne 0 ]; then
        print_info "Creating role assignment..."
        
        # Clean variables of any potential whitespace/newlines
        CLEAN_SP_APP_ID=$(echo "$SP_APP_ID" | tr -d '\r\n' | xargs)
        CLEAN_ACR_RESOURCE_ID=$(echo "$ACR_RESOURCE_ID" | tr -d '\r\n' | xargs)
        
        set +e
        ROLE_CREATE_OUTPUT=$(az role assignment create \
            --assignee "$CLEAN_SP_APP_ID" \
            --role "AcrPull" \
            --scope "$CLEAN_ACR_RESOURCE_ID" 2>&1)
        ROLE_CREATE_EXIT=$?
        set -e
        
        if [ $ROLE_CREATE_EXIT -eq 0 ]; then
            print_success "Role assignment created successfully"
        else
            print_error "Failed to create role assignment"
            echo ""
            echo "Error details:"
            echo "$ROLE_CREATE_OUTPUT"
            echo ""
            print_warning "Please create the role assignment manually:"
            echo "  az role assignment create --assignee $CLEAN_SP_APP_ID --role AcrPull --scope $CLEAN_ACR_RESOURCE_ID"
            echo ""
            read -p "Press Enter to continue (service principal created but role assignment failed)..."
        fi
    else
        print_success "Role assignment already exists ($ROLE_COUNT assignment(s) found)"
    fi
}

# Part 3: Setup US Gov Cloud AKS
setup_usgov_cloud() {
    print_header "PART 3: US Government Cloud AKS Setup"
    
    print_info "Switching to Azure US Government Cloud..."
    az cloud set --name AzureUSGovernment
    print_success "Switched to AzureUSGovernment"
    
    print_info "Logging into Azure US Government Cloud..."
    print_warning "Browser will open for authentication..."
    az login
    print_success "Logged into US Government Cloud"
    
    print_info "Setting subscription: $USGOV_SUB_ID"
    az account set --subscription "$USGOV_SUB_ID"
    print_success "Subscription set"
    
    print_info "Verifying AKS cluster..."
    az aks show \
        --resource-group "$AKS_RG" \
        --name "$AKS_NAME" \
        --query "{name:name, location:location, provisioningState:provisioningState}" \
        --output table
    
    print_success "AKS cluster verified"
    
    print_info "Downloading AKS credentials..."
    KUBECONFIG_FILE="kubeconfig-${CUSTOMER_ID}.yaml"
    az aks get-credentials \
        --resource-group "$AKS_RG" \
        --name "$AKS_NAME" \
        --file "$KUBECONFIG_FILE" \
        --overwrite-existing
    
    export KUBECONFIG="$KUBECONFIG_FILE"
    print_success "Kubeconfig saved to: $KUBECONFIG_FILE"
    
    print_info "Testing Kubernetes connection..."
    kubectl cluster-info
    print_success "Kubernetes connection verified"
}

# Part 4: Create Kubernetes Secret
create_k8s_secret() {
    print_header "PART 4: Create Kubernetes Secret"
    
    print_info "Creating namespace if it doesn't exist..."
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    print_info "Creating image pull secret: $SECRET_NAME"
    kubectl create secret docker-registry "$SECRET_NAME" \
        --namespace "$NAMESPACE" \
        --docker-server="$ACR_LOGIN_SERVER" \
        --docker-username="$SP_APP_ID" \
        --docker-password="$SP_PASSWORD" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "Secret created successfully"
    
    print_info "Verifying secret..."
    kubectl get secret "$SECRET_NAME" -n "$NAMESPACE"
    print_success "Secret verified"
}

# Part 5: Test Deployment
test_deployment() {
    print_header "PART 5: Test Deployment"
    
    print_info "Creating test pod manifest..."
    TEST_POD_FILE="test-cross-cloud-access-${CUSTOMER_ID}.yaml"
    
    cat > "$TEST_POD_FILE" <<EOF
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
      image: $ACR_LOGIN_SERVER/$TEST_IMAGE
      ports:
        - containerPort: 80
  restartPolicy: Never
EOF
    
    print_success "Test manifest created: $TEST_POD_FILE"
    
    print_info "Deploying test pod..."
    kubectl apply -f "$TEST_POD_FILE"
    
    print_info "Waiting 15 seconds for pod to start..."
    sleep 15
    
    print_info "Checking pod status..."
    kubectl get pod acr-test-pod -n "$NAMESPACE"
    
    echo ""
    POD_STATUS=$(kubectl get pod acr-test-pod -n "$NAMESPACE" -o jsonpath='{.status.phase}')
    
    if [ "$POD_STATUS" = "Running" ]; then
        print_success "Test pod is running! Cross-cloud access is working!"
    else
        print_warning "Pod status: $POD_STATUS"
        print_info "Getting detailed pod information..."
        kubectl describe pod acr-test-pod -n "$NAMESPACE"
    fi
    
    echo ""
    read -p "Do you want to delete the test pod? (yes/no): " DELETE_POD
    
    if [[ "$DELETE_POD" =~ ^[Yy][Ee][Ss]$ ]]; then
        kubectl delete pod acr-test-pod -n "$NAMESPACE"
        print_success "Test pod deleted"
    else
        print_info "Test pod left running"
    fi
}

# Main execution
main() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║      Cross-Cloud Azure Setup Script                       ║"
    echo "║      ACR (Public) → AKS (US Government)                   ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_prerequisites
    get_user_input
    
    setup_public_cloud
    create_service_principal
    setup_usgov_cloud
    create_k8s_secret
    test_deployment
    
    print_header "Setup Complete!"
    print_success "Cross-cloud connectivity established successfully!"
    
    echo ""
    print_info "Important files created:"
    echo "  - $CREDS_FILE (service principal credentials)"
    echo "  - $KUBECONFIG_FILE (Kubernetes config)"
    echo "  - $TEST_POD_FILE (test pod manifest)"
    
    echo ""
    print_warning "Next steps:"
    echo "  1. Store service principal credentials in secure location"
    echo "  2. Delete $CREDS_FILE after storing credentials"
    echo "  3. Use $SECRET_NAME in your deployments' imagePullSecrets"
    
    echo ""
    print_info "To use this kubeconfig in future sessions:"
    echo "  export KUBECONFIG=$KUBECONFIG_FILE"
}

# Run main function
main
