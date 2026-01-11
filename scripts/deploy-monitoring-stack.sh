#!/bin/bash

# Deploy monitoring stack (Prometheus + Headlamp) to clusters

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROMETHEUS_CHART="$PROJECT_DIR/charts/prometheus"
HEADLAMP_CHART="$PROJECT_DIR/charts/headlamp"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if context is provided
CONTEXT="${1:-}"
if [[ -z "$CONTEXT" ]]; then
    echo -e "${RED}Error: Cluster context required${NC}"
    echo "Usage: $0 <context>"
    echo ""
    echo "Available contexts:"
    kubectl config get-contexts -o name
    exit 1
fi

# Extract cluster name
CLUSTER_NAME=$(echo "$CONTEXT" | tr '[:upper:]' '[:lower:]' | tr '_' '-')

echo -e "${BLUE}=== Deploying monitoring stack to cluster: $CONTEXT ===${NC}\n"

# Deploy Prometheus
echo -e "${YELLOW}>>> Deploying Prometheus${NC}"
if helm upgrade prometheus "$PROMETHEUS_CHART" \
    --install \
    --kube-context="$CONTEXT" \
    --create-namespace \
    --namespace monitoring \
    --set config.global.external_labels.cluster="$CLUSTER_NAME" \
    --set ingress.enabled=false \
    --set service.type=NodePort \
    --set service.nodePort=30090 \
    --wait \
    --timeout 3m; then
    echo -e "${GREEN}✓ Prometheus deployed successfully${NC}\n"
else
    echo -e "${RED}✗ Prometheus deployment failed${NC}"
    exit 1
fi

# Deploy Headlamp (in-cluster mode)
echo -e "${YELLOW}>>> Deploying Headlamp${NC}"
if helm upgrade headlamp "$HEADLAMP_CHART" \
    --install \
    --kube-context="$CONTEXT" \
    --namespace monitoring \
    --set hostNetwork=false \
    --set hostKubeconfig.enabled=false \
    --set ingress.enabled=false \
    --set service.type=NodePort \
    --set nodePort.enabled=true \
    --set nodePort.port=30446 \
    --wait \
    --timeout 3m; then
    echo -e "${GREEN}✓ Headlamp deployed successfully${NC}\n"
else
    echo -e "${RED}✗ Headlamp deployment failed${NC}"
    exit 1
fi

# Get node IP
NODE_IP=$(kubectl get nodes --context="$CONTEXT" -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' | awk '{print $1}')

echo -e "\n${GREEN}=== Monitoring stack deployment complete! ===${NC}"
echo -e "\n${BLUE}Access URLs (replace <node-ip> with actual node IP if multi-node):${NC}"
echo -e "  Prometheus: ${YELLOW}http://${NODE_IP}:30090${NC}"
echo -e "  Headlamp:   ${YELLOW}http://${NODE_IP}:30446${NC}"
echo -e "\n${BLUE}Note:${NC} Headlamp will auto-discover Prometheus at: http://prometheus.monitoring.svc.cluster.local:9090"
