#!/bin/bash

# Kubernetes helper script for VSCode tasks
# Provides status, logs, events, resource usage monitoring and Helm operations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory to find charts folder
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CHARTS_DIR="$PROJECT_DIR/charts"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed or not in PATH${NC}"
    exit 1
fi

# Get the command
COMMAND="${1:-}"

if [[ -z "$COMMAND" ]]; then
    echo -e "${RED}Usage: $0 <command> [args...]${NC}"
    echo "kubectl commands: status, logs, events, resources (require YAML file)"
    echo "Helm commands: helm-install, helm-upgrade, helm-status, helm-logs, helm-uninstall"
    exit 1
fi

# For kubectl commands, we need a file
FILE="${2:-}"

# Extract namespace from YAML (default to 'default' if not specified)
get_namespace() {
    local ns
    ns=$(grep -m1 'namespace:' "$FILE" | awk '{print $2}' | tr -d ' ')
    echo "${ns:-default}"
}

# Extract app label selector from YAML
get_app_selector() {
    grep -E '^\s+app:\s+' "$FILE" | head -1 | sed 's/.*app:\s*//' | tr -d ' \r\n'
}

# Extract deployment name from YAML
get_deployment_name() {
    grep -A2 'kind: Deployment' "$FILE" | grep 'name:' | head -1 | awk '{print $2}' | tr -d ' '
}

case "$COMMAND" in
    status|logs|events|resources)
        # These commands require a YAML file
        if [[ -z "$FILE" || ! -f "$FILE" ]]; then
            echo -e "${RED}Error: YAML file not found: $FILE${NC}"
            exit 1
        fi
        NAMESPACE=$(get_namespace)
        ;;
esac

case "$COMMAND" in
    status)
        echo -e "${BLUE}=== Deployment Status ===${NC}"
        kubectl get -f "$FILE" -o wide 2>/dev/null || echo "No resources found"

        echo -e "\n${BLUE}=== Pod Status ===${NC}"
        APP_SELECTOR=$(get_app_selector)
        if [[ -n "$APP_SELECTOR" ]]; then
            kubectl get pods -n "$NAMESPACE" -l "app=$APP_SELECTOR" -o wide 2>/dev/null || echo "No pods found"
        else
            echo "Could not determine app selector"
        fi

        echo -e "\n${BLUE}=== Deployment Details ===${NC}"
        DEPLOYMENT=$(get_deployment_name)
        if [[ -n "$DEPLOYMENT" ]]; then
            kubectl describe deployment "$DEPLOYMENT" -n "$NAMESPACE" 2>/dev/null | head -50 || echo "Deployment not found"
        fi
        ;;

    logs)
        APP_SELECTOR=$(get_app_selector)
        if [[ -z "$APP_SELECTOR" ]]; then
            echo -e "${RED}Error: Could not determine app selector from YAML${NC}"
            exit 1
        fi

        echo -e "${BLUE}=== Streaming logs for app=$APP_SELECTOR ===${NC}"
        echo -e "${YELLOW}Press Ctrl+C to stop${NC}\n"

        POD=$(kubectl get pods -n "$NAMESPACE" -l "app=$APP_SELECTOR" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

        if [[ -z "$POD" ]]; then
            echo -e "${RED}No pods found with selector app=$APP_SELECTOR${NC}"
            exit 1
        fi

        echo -e "${GREEN}Following logs for pod: $POD${NC}\n"
        kubectl logs -f "$POD" -n "$NAMESPACE"
        ;;

    events)
        echo -e "${BLUE}=== Recent Events (namespace: $NAMESPACE) ===${NC}\n"

        APP_SELECTOR=$(get_app_selector)
        DEPLOYMENT=$(get_deployment_name)

        echo -e "${YELLOW}Events for deployment/$DEPLOYMENT:${NC}"
        kubectl get events -n "$NAMESPACE" --field-selector "involvedObject.name=$DEPLOYMENT" --sort-by='.lastTimestamp' 2>/dev/null | tail -20 || echo "No events found"

        echo -e "\n${YELLOW}Pod events:${NC}"
        if [[ -n "$APP_SELECTOR" ]]; then
            PODS=$(kubectl get pods -n "$NAMESPACE" -l "app=$APP_SELECTOR" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
            for POD in $PODS; do
                echo -e "\n${GREEN}Pod: $POD${NC}"
                kubectl get events -n "$NAMESPACE" --field-selector "involvedObject.name=$POD" --sort-by='.lastTimestamp' 2>/dev/null | tail -10 || echo "No events"
            done
        fi
        ;;

    resources)
        echo -e "${BLUE}=== Resource Usage (namespace: $NAMESPACE) ===${NC}\n"

        if ! kubectl top pods -n "$NAMESPACE" &>/dev/null; then
            echo -e "${YELLOW}Warning: Metrics server may not be installed or not ready${NC}"
            echo -e "Install with: kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml\n"
        fi

        APP_SELECTOR=$(get_app_selector)

        echo -e "${YELLOW}Pod Resource Usage:${NC}"
        if [[ -n "$APP_SELECTOR" ]]; then
            kubectl top pods -n "$NAMESPACE" -l "app=$APP_SELECTOR" 2>/dev/null || echo "Could not retrieve metrics"
        else
            kubectl top pods -n "$NAMESPACE" 2>/dev/null || echo "Could not retrieve metrics"
        fi

        echo -e "\n${YELLOW}Node Resource Usage:${NC}"
        kubectl top nodes 2>/dev/null || echo "Could not retrieve node metrics"
        ;;

    # Helm commands
    helm-install)
        if ! command -v helm &> /dev/null; then
            echo -e "${RED}Error: helm is not installed or not in PATH${NC}"
            exit 1
        fi

        CHART_NAME="${2:-}"
        RELEASE_NAME="${3:-$CHART_NAME}"
        CHART_PATH="$CHARTS_DIR/$CHART_NAME"
        # Capture extra arguments (--set, --values, etc.) starting from arg 4
        shift 3 2>/dev/null || shift $#
        EXTRA_ARGS=("$@")

        if [[ -z "$CHART_NAME" ]]; then
            echo -e "${RED}Error: Chart name required${NC}"
            echo "Usage: $0 helm-install <chart-name> [release-name] [--set key=value...]"
            exit 1
        fi

        if [[ ! -d "$CHART_PATH" ]]; then
            echo -e "${RED}Error: Chart not found at $CHART_PATH${NC}"
            exit 1
        fi

        echo -e "${BLUE}=== Installing Helm chart: $CHART_NAME ===${NC}"
        echo -e "${YELLOW}Release name: $RELEASE_NAME${NC}"
        if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
            echo -e "${YELLOW}Extra args: ${EXTRA_ARGS[*]}${NC}"
        fi
        echo ""

        helm install "$RELEASE_NAME" "$CHART_PATH" --wait "${EXTRA_ARGS[@]}"

        echo -e "\n${GREEN}Installation complete!${NC}"
        echo -e "\n${BLUE}=== Release Status ===${NC}"
        helm status "$RELEASE_NAME"
        ;;

    helm-upgrade)
        if ! command -v helm &> /dev/null; then
            echo -e "${RED}Error: helm is not installed or not in PATH${NC}"
            exit 1
        fi

        CHART_NAME="${2:-}"
        RELEASE_NAME="${3:-$CHART_NAME}"
        CHART_PATH="$CHARTS_DIR/$CHART_NAME"
        # Capture extra arguments (--set, --values, etc.) starting from arg 4
        shift 3 2>/dev/null || shift $#
        EXTRA_ARGS=("$@")

        if [[ -z "$CHART_NAME" ]]; then
            echo -e "${RED}Error: Chart name required${NC}"
            echo "Usage: $0 helm-upgrade <chart-name> [release-name] [--set key=value...]"
            exit 1
        fi

        if [[ ! -d "$CHART_PATH" ]]; then
            echo -e "${RED}Error: Chart not found at $CHART_PATH${NC}"
            exit 1
        fi

        echo -e "${BLUE}=== Upgrading Helm release: $RELEASE_NAME ===${NC}"
        if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
            echo -e "${YELLOW}Extra args: ${EXTRA_ARGS[*]}${NC}"
        fi
        echo ""

        # Check for other releases using the same chart (potential conflicts)
        CONFLICTING_RELEASES=$(helm list --output json | jq -r --arg chart "$CHART_NAME" --arg release "$RELEASE_NAME" \
            '.[] | select(.chart | contains($chart)) | select(.name != $release) | .name' 2>/dev/null)

        if [[ -n "$CONFLICTING_RELEASES" ]]; then
            echo -e "${YELLOW}=== Found other releases using the same chart ===${NC}"
            echo -e "These releases may conflict (e.g., hostPort bindings):\n"
            for rel in $CONFLICTING_RELEASES; do
                echo -e "  - ${YELLOW}$rel${NC}"
            done
            echo -e "\n${YELLOW}Uninstalling conflicting releases...${NC}\n"
            for rel in $CONFLICTING_RELEASES; do
                echo -e "Uninstalling: $rel"
                helm uninstall "$rel" --wait 2>/dev/null || true
            done
            echo ""
        fi

        helm upgrade "$RELEASE_NAME" "$CHART_PATH" --install --wait "${EXTRA_ARGS[@]}"

        echo -e "\n${GREEN}Upgrade complete!${NC}"
        echo -e "\n${BLUE}=== Release Status ===${NC}"
        helm status "$RELEASE_NAME"
        ;;

    helm-status)
        if ! command -v helm &> /dev/null; then
            echo -e "${RED}Error: helm is not installed or not in PATH${NC}"
            exit 1
        fi

        RELEASE_NAME="${2:-}"

        if [[ -z "$RELEASE_NAME" ]]; then
            echo -e "${RED}Error: Release name required${NC}"
            echo "Usage: $0 helm-status <release-name>"
            exit 1
        fi

        echo -e "${BLUE}=== Helm Release Status: $RELEASE_NAME ===${NC}\n"
        helm status "$RELEASE_NAME"

        echo -e "\n${BLUE}=== Deployed Resources ===${NC}"
        helm get manifest "$RELEASE_NAME" | kubectl get -f - 2>/dev/null || echo "Could not get resources"

        echo -e "\n${BLUE}=== Pod Status ===${NC}"
        # Get pods from the release
        kubectl get pods -l "app.kubernetes.io/instance=$RELEASE_NAME" -o wide 2>/dev/null || \
        kubectl get pods -l "app=$RELEASE_NAME-server" -o wide 2>/dev/null || \
        echo "No pods found for release"
        ;;

    helm-logs)
        if ! command -v helm &> /dev/null; then
            echo -e "${RED}Error: helm is not installed or not in PATH${NC}"
            exit 1
        fi

        RELEASE_NAME="${2:-}"

        if [[ -z "$RELEASE_NAME" ]]; then
            echo -e "${RED}Error: Release name required${NC}"
            echo "Usage: $0 helm-logs <release-name>"
            exit 1
        fi

        echo -e "${BLUE}=== Streaming logs for release: $RELEASE_NAME ===${NC}"
        echo -e "${YELLOW}Press Ctrl+C to stop${NC}\n"

        # Try different label selectors to find pods
        POD=$(kubectl get pods -l "app.kubernetes.io/instance=$RELEASE_NAME" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

        if [[ -z "$POD" ]]; then
            POD=$(kubectl get pods -l "app=$RELEASE_NAME-server" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        fi

        if [[ -z "$POD" ]]; then
            echo -e "${RED}No pods found for release $RELEASE_NAME${NC}"
            echo "Available pods:"
            kubectl get pods
            exit 1
        fi

        echo -e "${GREEN}Following logs for pod: $POD${NC}\n"
        kubectl logs -f "$POD"
        ;;

    helm-restart)
        RELEASE_NAME="${2:-}"

        if [[ -z "$RELEASE_NAME" ]]; then
            echo -e "${RED}Error: Release name required${NC}"
            echo "Usage: $0 helm-restart <release-name>"
            exit 1
        fi

        echo -e "${BLUE}=== Restarting pods for release: $RELEASE_NAME ===${NC}"
        echo -e "${YELLOW}This will pull the latest image and restart the pod${NC}\n"

        # Find deployments for this release
        DEPLOYMENTS=$(kubectl get deployments -l "app.kubernetes.io/instance=$RELEASE_NAME" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)

        if [[ -z "$DEPLOYMENTS" ]]; then
            echo -e "${RED}No deployments found for release $RELEASE_NAME${NC}"
            exit 1
        fi

        for DEPLOYMENT in $DEPLOYMENTS; do
            echo -e "${GREEN}Restarting deployment: $DEPLOYMENT${NC}"
            kubectl rollout restart deployment "$DEPLOYMENT"
        done

        echo -e "\n${YELLOW}Waiting for rollout to complete...${NC}"
        for DEPLOYMENT in $DEPLOYMENTS; do
            kubectl rollout status deployment "$DEPLOYMENT" --timeout=120s
        done

        echo -e "\n${GREEN}Restart complete!${NC}"
        echo -e "\n${BLUE}=== Pod Status ===${NC}"
        kubectl get pods -l "app.kubernetes.io/instance=$RELEASE_NAME" -o wide
        ;;

    helm-uninstall)
        if ! command -v helm &> /dev/null; then
            echo -e "${RED}Error: helm is not installed or not in PATH${NC}"
            exit 1
        fi

        RELEASE_NAME="${2:-}"

        if [[ -z "$RELEASE_NAME" ]]; then
            echo -e "${RED}Error: Release name required${NC}"
            echo "Usage: $0 helm-uninstall <release-name>"
            exit 1
        fi

        echo -e "${BLUE}=== Uninstalling Helm release: $RELEASE_NAME ===${NC}\n"

        helm uninstall "$RELEASE_NAME"

        echo -e "\n${GREEN}Release $RELEASE_NAME uninstalled successfully!${NC}"
        ;;

    *)
        echo -e "${RED}Unknown command: $COMMAND${NC}"
        echo "kubectl commands: status, logs, events, resources"
        echo "Helm commands: helm-install, helm-upgrade, helm-status, helm-logs, helm-restart, helm-uninstall"
        exit 1
        ;;
esac
