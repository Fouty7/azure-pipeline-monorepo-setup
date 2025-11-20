#!/bin/bash
#===============================================================================
# Manifest-Based Deployment Script
# Purpose: Deploy services to Kubernetes based on YAML manifest
#===============================================================================

set -e  # Exit on any error

MANIFEST_FILE=${1:-"manifests/riic-release-1.0-test.yaml"}
NAMESPACE=${2:-"default"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Check if manifest file exists
if [ ! -f "$MANIFEST_FILE" ]; then
    print_error "Manifest file not found: $MANIFEST_FILE"
    exit 1
fi

print_header "Deploying from Manifest: $MANIFEST_FILE"

# Extract release info
RELEASE_NAME=$(yq eval '.release.name' "$MANIFEST_FILE")
RELEASE_ENV=$(yq eval '.release.environment' "$MANIFEST_FILE")
RELEASE_DESC=$(yq eval '.release.description' "$MANIFEST_FILE")

echo "Release Name: $RELEASE_NAME"
echo "Environment: $RELEASE_ENV"
echo "Description: $RELEASE_DESC"
echo ""

# Get number of services
SERVICE_COUNT=$(yq eval '.services | length' "$MANIFEST_FILE")
print_info "Found $SERVICE_COUNT services in manifest"
echo ""

# Deploy each service
for i in $(seq 0 $((SERVICE_COUNT - 1))); do
    # Extract service details
    SERVICE_NAME=$(yq eval ".services[$i].name" "$MANIFEST_FILE")
    ENABLED=$(yq eval ".services[$i].enabled" "$MANIFEST_FILE")
    
    # Skip if disabled
    if [ "$ENABLED" != "true" ]; then
        print_info "Skipping $SERVICE_NAME (disabled)"
        continue
    fi
    
    print_header "Deploying: $SERVICE_NAME"
    
    # Extract Helm details
    CHART=$(yq eval ".services[$i].helm.chart" "$MANIFEST_FILE")
    RELEASE=$(yq eval ".services[$i].helm.releaseName" "$MANIFEST_FILE")
    VALUES_FILE=$(yq eval ".services[$i].helm.valuesFile" "$MANIFEST_FILE")
    SVC_NAMESPACE=$(yq eval ".services[$i].helm.namespace" "$MANIFEST_FILE")
    
    # Use service-specific namespace if provided, otherwise use default
    DEPLOY_NAMESPACE="${SVC_NAMESPACE:-$NAMESPACE}"
    
    # Extract image details (may not exist for dependencies like Redis)
    IMAGE_REPO=$(yq eval ".services[$i].image.repository" "$MANIFEST_FILE")
    IMAGE_TAG=$(yq eval ".services[$i].image.tag" "$MANIFEST_FILE")
    
    echo "  Chart: $CHART"
    echo "  Release: $RELEASE"
    echo "  Namespace: $DEPLOY_NAMESPACE"
    
    if [ "$IMAGE_REPO" != "null" ] && [ "$IMAGE_TAG" != "null" ]; then
        echo "  Image: $IMAGE_REPO:$IMAGE_TAG"
    fi
    
    # Build Helm command
    HELM_CMD="helm upgrade --install $RELEASE $CHART"
    HELM_CMD="$HELM_CMD --namespace $DEPLOY_NAMESPACE"
    HELM_CMD="$HELM_CMD --create-namespace"
    
    # Add image overrides if specified
    if [ "$IMAGE_REPO" != "null" ] && [ "$IMAGE_TAG" != "null" ]; then
        HELM_CMD="$HELM_CMD --set image.repository=$IMAGE_REPO"
        HELM_CMD="$HELM_CMD --set image.tag=$IMAGE_TAG"
    fi
    
    # Add values file if specified and exists
    if [ "$VALUES_FILE" != "null" ] && [ -f "$VALUES_FILE" ]; then
        HELM_CMD="$HELM_CMD -f $VALUES_FILE"
        echo "  Values File: $VALUES_FILE"
    fi
    
    echo ""
    print_info "Running: $HELM_CMD"
    echo ""
    
    # Execute deployment
    if eval $HELM_CMD; then
        print_success "$SERVICE_NAME deployed successfully"
    else
        print_error "Failed to deploy $SERVICE_NAME"
        exit 1
    fi
    
    echo ""
done

print_header "Deployment Complete!"
print_success "All services from $MANIFEST_FILE deployed successfully to namespace: $NAMESPACE"
