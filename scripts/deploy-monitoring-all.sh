#!/bin/bash

# Deploy monitoring stack to all clusters

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Deploying monitoring stack to all clusters ===${NC}\n"

# Get all contexts
CONTEXTS=$(kubectl config get-contexts -o name)

# Track results
SUCCESSFUL=()
FAILED=()

for CONTEXT in $CONTEXTS; do
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}>>> Processing cluster: $CONTEXT${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"
    
    if "$SCRIPT_DIR/deploy-monitoring-stack.sh" "$CONTEXT" 2>&1; then
        SUCCESSFUL+=("$CONTEXT")
    else
        FAILED+=("$CONTEXT")
    fi
    
    echo ""
done

# Summary
echo -e "\n${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}=== Deployment Summary ===${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Successful (${#SUCCESSFUL[@]}):${NC}"
for ctx in "${SUCCESSFUL[@]}"; do
    NODE_IP=$(kubectl get nodes --context="$ctx" -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null | awk '{print $1}')
    echo -e "  ✓ $ctx"
    echo -e "    Prometheus: http://${NODE_IP}:30090"
    echo -e "    Headlamp:   http://${NODE_IP}:30446"
done

if [ ${#FAILED[@]} -gt 0 ]; then
    echo -e "\n${RED}Failed (${#FAILED[@]}):${NC}"
    for ctx in "${FAILED[@]}"; do
        echo -e "  ✗ $ctx"
    done
    exit 1
fi

echo -e "\n${GREEN}All deployments completed successfully!${NC}"
