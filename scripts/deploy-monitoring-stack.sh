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
    --set ingress.hosts[0].host="prometheus-${CLUSTER_NAME}.baezw.com" \
    --set ingress.hosts[0].paths[0].path="/" \
    --set ingress.hosts[0].paths[0].pathType="Prefix" \
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
    --set ingress.enabled=true \
    --set ingress.hosts[0].host="headlamp-${CLUSTER_NAME}.baezw.com" \
    --set ingress.hosts[0].paths[0].path="/" \
    --set ingress.hosts[0].paths[0].pathType="Prefix" \
    --set service.type=ClusterIP \
    --set nodePort.enabled=false \
    --wait \
    --timeout 3m; then
    echo -e "${GREEN}✓ Headlamp deployed successfully${NC}\n"
else
    echo -e "${RED}✗ Headlamp deployment failed${NC}"
    exit 1
fi

echo -e "\n${GREEN}=== Monitoring stack deployment complete! ===${NC}"
echo -e "\n${BLUE}Access URLs:${NC}"
echo -e "  Prometheus: ${YELLOW}https://prometheus-${CLUSTER_NAME}.baezw.com${NC}"
echo -e "  Headlamp:   ${YELLOW}https://headlamp-${CLUSTER_NAME}.baezw.com${NC}"
echo -e "\n${BLUE}Note:${NC} Headlamp will auto-discover Prometheus at: http://prometheus.monitoring.svc.cluster.local:9090"
