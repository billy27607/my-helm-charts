#!/bin/bash

# Deploy Prometheus to all available clusters

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CHART_PATH="$PROJECT_DIR/charts/prometheus"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Deploying Prometheus to all clusters ===${NC}\n"

# Get all contexts
CONTEXTS=$(kubectl config get-contexts -o name)

# Track results
SUCCESSFUL=()
FAILED=()

for CONTEXT in $CONTEXTS; do
    echo -e "${YELLOW}>>> Deploying to cluster: $CONTEXT${NC}"
    
    # Extract cluster name for label and hostname
    CLUSTER_NAME=$(echo "$CONTEXT" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
    
    # Install/upgrade Prometheus with cluster-specific external label and hostname
    if helm upgrade prometheus "$CHART_PATH" \
        --install \
        --kube-context="$CONTEXT" \
        --create-namespace \
        --namespace monitoring \
        --set config.global.external_labels.cluster="$CLUSTER_NAME" \
        --set ingress.hosts[0].host="prometheus-${CLUSTER_NAME}.baezw.com" \
        --wait \
        --timeout 2m 2>&1; then
        
        echo -e "${GREEN}✓ Successfully deployed to $CONTEXT${NC}\n"
        SUCCESSFUL+=("$CONTEXT")
    else
        echo -e "${RED}✗ Failed to deploy to $CONTEXT${NC}\n"
        FAILED+=("$CONTEXT")
    fi
done

# Summary
echo -e "\n${BLUE}=== Deployment Summary ===${NC}"
echo -e "${GREEN}Successful (${#SUCCESSFUL[@]}):${NC}"
for ctx in "${SUCCESSFUL[@]}"; do
    echo -e "  ✓ $ctx"
done

if [ ${#FAILED[@]} -gt 0 ]; then
    echo -e "\n${RED}Failed (${#FAILED[@]}):${NC}"
    for ctx in "${FAILED[@]}"; do
        echo -e "  ✗ $ctx"
    done
    exit 1
fi

echo -e "\n${GREEN}All deployments completed successfully!${NC}"
echo -e "\n${YELLOW}Access Prometheus on each cluster at: http://<node-ip>:30090${NC}"
