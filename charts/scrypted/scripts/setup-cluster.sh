#!/bin/bash
# Setup script for Scrypted cluster prerequisites
# Run this once per cluster before installing the Helm chart

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Scrypted Cluster Setup ===${NC}\n"

# Check kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl not found${NC}"
    exit 1
fi

# Intel GPU Device Plugin
install_intel_gpu() {
    echo -e "${YELLOW}Installing Intel GPU Device Plugin...${NC}"

    # Check if already installed
    if kubectl get daemonset -n kube-system intel-gpu-plugin &> /dev/null; then
        echo -e "${GREEN}Intel GPU plugin already installed${NC}"
        return 0
    fi

    # Install the plugin
    kubectl apply -f https://raw.githubusercontent.com/intel/intel-device-plugins-for-kubernetes/main/deployments/gpu_plugin/base/intel-gpu-plugin.yaml

    # Wait for it to be ready
    echo -e "${YELLOW}Waiting for Intel GPU plugin to be ready...${NC}"
    kubectl rollout status daemonset/intel-gpu-plugin -n kube-system --timeout=60s || true

    # Verify GPU is detected
    sleep 5
    GPU_COUNT=$(kubectl get nodes -o jsonpath='{.items[*].status.allocatable.gpu\.intel\.com/i915}' 2>/dev/null | tr ' ' '\n' | grep -v '^$' | head -1)

    if [[ -n "$GPU_COUNT" && "$GPU_COUNT" != "0" ]]; then
        echo -e "${GREEN}Intel GPU detected: $GPU_COUNT available${NC}"
    else
        echo -e "${YELLOW}Warning: No Intel GPU detected on nodes. Check if /dev/dri exists on host.${NC}"
    fi
}

# Node Feature Discovery (optional, for auto-detecting hardware)
install_nfd() {
    echo -e "${YELLOW}Installing Node Feature Discovery...${NC}"

    if kubectl get daemonset -n node-feature-discovery nfd-worker &> /dev/null; then
        echo -e "${GREEN}NFD already installed${NC}"
        return 0
    fi

    kubectl apply -k https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/nfd?ref=main
    kubectl rollout status daemonset/nfd-worker -n node-feature-discovery --timeout=60s || true
}

# Parse arguments
INSTALL_NFD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --with-nfd)
            INSTALL_NFD=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --with-nfd    Also install Node Feature Discovery"
            echo "  --help        Show this help"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Run installations
install_intel_gpu

if [[ "$INSTALL_NFD" == "true" ]]; then
    install_nfd
fi

echo -e "\n${GREEN}=== Setup Complete ===${NC}"
echo -e "You can now install the Scrypted Helm chart:"
echo -e "  ${BLUE}helm install scrypted ./charts/scrypted${NC}"
