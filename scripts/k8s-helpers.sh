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

# Function to wait for service readiness by checking logs
wait_for_service_ready() {
    local release_name="$1"
    local namespace="$2"
    local timeout="${3:-120}"  # Default 120 seconds timeout
    local ready_pattern="${4:-service ready|Starting server|Started}"  # Default patterns
    
    echo -e "\n${BLUE}=== Waiting for service to be ready ===${NC}"
    echo -e "${YELLOW}Checking logs for: $ready_pattern${NC}"
    
    local elapsed=0
    local pod_name=""
    
    # First wait for pod to exist
    while [[ $elapsed -lt $timeout ]]; do
        pod_name=$(kubectl get pods -n "$namespace" -l "app.kubernetes.io/instance=$release_name" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        if [[ -n "$pod_name" ]]; then
            break
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done
    
    if [[ -z "$pod_name" ]]; then
        echo -e "${YELLOW}Warning: Could not find pod for release $release_name${NC}"
        return 0  # Don't fail, just warn
    fi
    
    echo -e "${YELLOW}Waiting for pod $pod_name to be ready...${NC}"
    
    # Wait for pod to be Running
    while [[ $elapsed -lt $timeout ]]; do
        local pod_status=$(kubectl get pod "$pod_name" -n "$namespace" -o jsonpath='{.status.phase}' 2>/dev/null)
        if [[ "$pod_status" == "Running" ]]; then
            break
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done
    
    # Now check logs for service ready message
    echo -e "${YELLOW}Checking service logs for readiness...${NC}"
    while [[ $elapsed -lt $timeout ]]; do
        if kubectl logs "$pod_name" -n "$namespace" 2>/dev/null | grep -qiE "$ready_pattern"; then
            echo -e "${GREEN}✓ Service is ready!${NC}"
            return 0
        fi
        sleep 3
        elapsed=$((elapsed + 3))
        # Show a progress indicator every 15 seconds
        if [[ $((elapsed % 15)) -eq 0 ]]; then
            echo -e "${YELLOW}  Still waiting... ($elapsed seconds elapsed)${NC}"
        fi
    done
    
    echo -e "${YELLOW}Warning: Timeout waiting for service ready message after ${timeout}s${NC}"
    echo -e "${YELLOW}Service may still be initializing. Check logs with: kubectl logs $pod_name -n $namespace${NC}"
    return 0  # Don't fail the deployment, just warn
}

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
        # Capture extra arguments (--set, --values, --namespace, etc.) starting from arg 4
        shift 3 2>/dev/null || shift $#
        # Filter out empty strings from arguments
        EXTRA_ARGS=()
        for arg in "$@"; do
            [[ -n "$arg" ]] && EXTRA_ARGS+=("$arg")
        done

        if [[ -z "$CHART_NAME" ]]; then
            echo -e "${RED}Error: Chart name required${NC}"
            echo "Usage: $0 helm-install <chart-name> [release-name] [--set key=value...] [--namespace namespace]"
            exit 1
        fi

        if [[ ! -d "$CHART_PATH" ]]; then
            echo -e "${RED}Error: Chart not found at $CHART_PATH${NC}"
            exit 1
        fi

        # Default to monitoring namespace only for prometheus and headlamp charts
        if [[ ! " ${EXTRA_ARGS[*]} " =~ " --namespace " ]] && [[ ! " ${EXTRA_ARGS[*]} " =~ " -n " ]]; then
            if [[ "$CHART_NAME" == "prometheus" || "$CHART_NAME" == "headlamp" ]]; then
                EXTRA_ARGS+=("--namespace" "monitoring")
            fi
        fi

        echo -e "${BLUE}=== Installing Helm chart: $CHART_NAME ===${NC}"
        echo -e "${YELLOW}Release name: $RELEASE_NAME${NC}"
        if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
            echo -e "${YELLOW}Extra args: ${EXTRA_ARGS[*]}${NC}"
        fi
        echo ""

        helm install "$RELEASE_NAME" "$CHART_PATH" --create-namespace --wait "${EXTRA_ARGS[@]}"

        echo -e "\n${GREEN}Installation complete!${NC}"
        
        # Extract namespace for service verification
        NAMESPACE="default"
        for i in "${!EXTRA_ARGS[@]}"; do
            if [[ "${EXTRA_ARGS[$i]}" == "--namespace" || "${EXTRA_ARGS[$i]}" == "-n" ]]; then
                NAMESPACE="${EXTRA_ARGS[$((i+1))]}"
                break
            elif [[ "${EXTRA_ARGS[$i]}" == "--namespace="* ]]; then
                NAMESPACE="${EXTRA_ARGS[$i]#*=}"
                break
            fi
        done
        
        # Wait for service to be ready
        wait_for_service_ready "$RELEASE_NAME" "$NAMESPACE" 120 "service ready|Starting server|Started|Listening on"
        
        echo -e "\n${BLUE}=== Release Status ===${NC}"
        # Extract namespace from EXTRA_ARGS for status command
        NAMESPACE_ARG=()
        for i in "${!EXTRA_ARGS[@]}"; do
            if [[ "${EXTRA_ARGS[$i]}" == "--namespace="* || "${EXTRA_ARGS[$i]}" == "-n="* ]]; then
                # Format: --namespace=value
                NAMESPACE_ARG=("${EXTRA_ARGS[$i]}")
                break
            elif [[ "${EXTRA_ARGS[$i]}" == "--namespace" || "${EXTRA_ARGS[$i]}" == "-n" ]]; then
                # Format: --namespace value
                NAMESPACE_ARG=("${EXTRA_ARGS[$i]}" "${EXTRA_ARGS[$((i+1))]}")
                break
            fi
        done
        helm status "$RELEASE_NAME" "${NAMESPACE_ARG[@]}"
        ;;

    helm-upgrade)
        if ! command -v helm &> /dev/null; then
            echo -e "${RED}Error: helm is not installed or not in PATH${NC}"
            exit 1
        fi

        CHART_NAME="${2:-}"
        RELEASE_NAME="${3:-$CHART_NAME}"
        CHART_PATH="$CHARTS_DIR/$CHART_NAME"
        # Capture extra arguments (--set, --values, --namespace, etc.) starting from arg 4
        shift 3 2>/dev/null || shift $#
        # Filter out empty strings from arguments
        EXTRA_ARGS=()
        for arg in "$@"; do
            [[ -n "$arg" ]] && EXTRA_ARGS+=("$arg")
        done

        if [[ -z "$CHART_NAME" ]]; then
            echo -e "${RED}Error: Chart name required${NC}"
            echo "Usage: $0 helm-upgrade <chart-name> [release-name] [--set key=value...] [--namespace namespace]"
            exit 1
        fi

        # Default to monitoring namespace only for prometheus and headlamp charts
        if [[ ! " ${EXTRA_ARGS[*]} " =~ " --namespace " ]] && [[ ! " ${EXTRA_ARGS[*]} " =~ " -n " ]]; then
            if [[ "$CHART_NAME" == "prometheus" || "$CHART_NAME" == "headlamp" ]]; then
                EXTRA_ARGS+=("--namespace" "monitoring")
            fi
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
        # First check in all namespaces
        CONFLICTING_RELEASES=$(helm list -A --output json | jq -r --arg chart "$CHART_NAME" --arg release "$RELEASE_NAME" \
            '.[] | select(.chart | contains($chart)) | select(.name != $release) | "\(.namespace):\(.name)"' 2>/dev/null)

        if [[ -n "$CONFLICTING_RELEASES" ]]; then
            echo -e "${YELLOW}=== Found other releases using the same chart ===${NC}"
            echo -e "These releases may conflict (e.g., hostPort bindings):\n"
            echo "$CONFLICTING_RELEASES" | while IFS=: read -r ns rel; do
                echo -e "  - ${YELLOW}$rel${NC} (namespace: $ns)"
            done
            echo -e "\n${YELLOW}Uninstalling conflicting releases...${NC}\n"
            echo "$CONFLICTING_RELEASES" | while IFS=: read -r ns rel; do
                echo -e "Uninstalling: $rel from namespace $ns"
                helm uninstall "$rel" --namespace "$ns" --wait 2>/dev/null || true
            done
            echo ""
        fi

        helm upgrade "$RELEASE_NAME" "$CHART_PATH" --install --wait "${EXTRA_ARGS[@]}"

        echo -e "\n${GREEN}Upgrade complete!${NC}"
        
        # Extract namespace for service verification
        NAMESPACE="default"
        for i in "${!EXTRA_ARGS[@]}"; do
            if [[ "${EXTRA_ARGS[$i]}" == "--namespace" || "${EXTRA_ARGS[$i]}" == "-n" ]]; then
                NAMESPACE="${EXTRA_ARGS[$((i+1))]}"
                break
            elif [[ "${EXTRA_ARGS[$i]}" == "--namespace="* ]]; then
                NAMESPACE="${EXTRA_ARGS[$i]#*=}"
                break
            fi
        done
        
        # Wait for service to be ready
        wait_for_service_ready "$RELEASE_NAME" "$NAMESPACE" 120 "service ready|Starting server|Started|Listening on"
        
        echo -e "\n${BLUE}=== Release Status ===${NC}"
        # Extract namespace from EXTRA_ARGS for status command
        NAMESPACE_ARG=()
        for i in "${!EXTRA_ARGS[@]}"; do
            if [[ "${EXTRA_ARGS[$i]}" == "--namespace="* || "${EXTRA_ARGS[$i]}" == "-n="* ]]; then
                # Format: --namespace=value
                NAMESPACE_ARG=("${EXTRA_ARGS[$i]}")
                break
            elif [[ "${EXTRA_ARGS[$i]}" == "--namespace" || "${EXTRA_ARGS[$i]}" == "-n" ]]; then
                # Format: --namespace value
                NAMESPACE_ARG=("${EXTRA_ARGS[$i]}" "${EXTRA_ARGS[$((i+1))]}")
                break
            fi
        done
        helm status "$RELEASE_NAME" "${NAMESPACE_ARG[@]}"
        ;;

    helm-status)
        if ! command -v helm &> /dev/null; then
            echo -e "${RED}Error: helm is not installed or not in PATH${NC}"
            exit 1
        fi

        RELEASE_NAME="${2:-}"
        # Capture extra arguments (--namespace, etc.) starting from arg 3
        shift 2 2>/dev/null || shift $#
        # Filter out empty strings from arguments
        EXTRA_ARGS=()
        for arg in "$@"; do
            [[ -n "$arg" ]] && EXTRA_ARGS+=("$arg")
        done

        if [[ -z "$RELEASE_NAME" ]]; then
            echo -e "${RED}Error: Release name required${NC}"
            echo "Usage: $0 helm-status <release-name> [--namespace namespace]"
            exit 1
        fi

        echo -e "${BLUE}=== Helm Release Status: $RELEASE_NAME ===${NC}\n"
        helm status "$RELEASE_NAME" "${EXTRA_ARGS[@]}"

        echo -e "\n${BLUE}=== Deployed Resources ===${NC}"
        helm get manifest "$RELEASE_NAME" "${EXTRA_ARGS[@]}" | kubectl get -f - 2>/dev/null || echo "Could not get resources"

        echo -e "\n${BLUE}=== Pod Status ===${NC}"
        # Extract namespace for kubectl commands
        NAMESPACE="default"
        for i in "${!EXTRA_ARGS[@]}"; do
            if [[ "${EXTRA_ARGS[$i]}" == "--namespace" || "${EXTRA_ARGS[$i]}" == "-n" ]]; then
                NAMESPACE="${EXTRA_ARGS[$((i+1))]}"
                break
            fi
        done
        # Get pods from the release
        kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME" -o wide 2>/dev/null || \
        kubectl get pods -n "$NAMESPACE" -l "app=$RELEASE_NAME-server" -o wide 2>/dev/null || \
        echo "No pods found for release"
        ;;

    helm-logs)
        if ! command -v helm &> /dev/null; then
            echo -e "${RED}Error: helm is not installed or not in PATH${NC}"
            exit 1
        fi

        RELEASE_NAME="${2:-}"
        # Capture extra arguments (--namespace, etc.) starting from arg 3
        shift 2 2>/dev/null || shift $#
        # Filter out empty strings from arguments
        EXTRA_ARGS=()
        for arg in "$@"; do
            [[ -n "$arg" ]] && EXTRA_ARGS+=("$arg")
        done

        if [[ -z "$RELEASE_NAME" ]]; then
            echo -e "${RED}Error: Release name required${NC}"
            echo "Usage: $0 helm-logs <release-name> [--namespace namespace]"
            exit 1
        fi

        # Extract namespace for kubectl commands
        NAMESPACE="default"
        for i in "${!EXTRA_ARGS[@]}"; do
            if [[ "${EXTRA_ARGS[$i]}" == "--namespace" || "${EXTRA_ARGS[$i]}" == "-n" ]]; then
                NAMESPACE="${EXTRA_ARGS[$((i+1))]}"
                break
            fi
        done

        echo -e "${BLUE}=== Streaming logs for release: $RELEASE_NAME ===${NC}"
        echo -e "${YELLOW}Press Ctrl+C to stop${NC}\n"

        # Try different label selectors to find pods
        POD=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

        if [[ -z "$POD" ]]; then
            POD=$(kubectl get pods -n "$NAMESPACE" -l "app=$RELEASE_NAME" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        fi

        if [[ -z "$POD" ]]; then
            POD=$(kubectl get pods -n "$NAMESPACE" -l "app=$RELEASE_NAME-server" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        fi

        if [[ -z "$POD" ]]; then
            echo -e "${RED}No pods found for release $RELEASE_NAME in namespace $NAMESPACE${NC}"
            echo "Available pods:"
            kubectl get pods -n "$NAMESPACE"
            exit 1
        fi

        echo -e "${GREEN}Following logs for pod: $POD${NC}\n"
        kubectl logs -n "$NAMESPACE" -f "$POD"
        ;;

    helm-restart)
        RELEASE_NAME="${2:-}"
        # Capture extra arguments (--namespace, etc.) starting from arg 3
        shift 2 2>/dev/null || shift $#
        # Filter out empty strings from arguments
        EXTRA_ARGS=()
        for arg in "$@"; do
            [[ -n "$arg" ]] && EXTRA_ARGS+=("$arg")
        done

        if [[ -z "$RELEASE_NAME" ]]; then
            echo -e "${RED}Error: Release name required${NC}"
            echo "Usage: $0 helm-restart <release-name> [--namespace namespace]"
            exit 1
        fi

        # Extract namespace for kubectl commands
        NAMESPACE="default"
        for i in "${!EXTRA_ARGS[@]}"; do
            if [[ "${EXTRA_ARGS[$i]}" == "--namespace" || "${EXTRA_ARGS[$i]}" == "-n" ]]; then
                NAMESPACE="${EXTRA_ARGS[$((i+1))]}"
                break
            fi
        done

        echo -e "${BLUE}=== Restarting pods for release: $RELEASE_NAME ===${NC}"
        echo -e "${YELLOW}This will pull the latest image and restart the pod${NC}\n"

        # Find deployments for this release
        DEPLOYMENTS=$(kubectl get deployments -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)

        if [[ -z "$DEPLOYMENTS" ]]; then
            echo -e "${RED}No deployments found for release $RELEASE_NAME in namespace $NAMESPACE${NC}"
            exit 1
        fi

        for DEPLOYMENT in $DEPLOYMENTS; do
            echo -e "${GREEN}Restarting deployment: $DEPLOYMENT${NC}"
            kubectl rollout restart deployment "$DEPLOYMENT" -n "$NAMESPACE"
        done

        echo -e "\n${YELLOW}Waiting for rollout to complete...${NC}"
        for DEPLOYMENT in $DEPLOYMENTS; do
            kubectl rollout status deployment "$DEPLOYMENT" -n "$NAMESPACE" --timeout=120s
        done

        echo -e "\n${GREEN}Restart complete!${NC}"
        echo -e "\n${BLUE}=== Pod Status ===${NC}"
        kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE_NAME" -o wide
        ;;

    helm-uninstall)
        if ! command -v helm &> /dev/null; then
            echo -e "${RED}Error: helm is not installed or not in PATH${NC}"
            exit 1
        fi

        RELEASE_NAME="${2:-}"
        # Capture extra arguments (--namespace, etc.) starting from arg 3
        shift 2 2>/dev/null || shift $#
        # Filter out empty strings from arguments
        EXTRA_ARGS=()
        for arg in "$@"; do
            [[ -n "$arg" ]] && EXTRA_ARGS+=("$arg")
        done

        if [[ -z "$RELEASE_NAME" ]]; then
            echo -e "${RED}Error: Release name required${NC}"
            echo "Usage: $0 helm-uninstall <release-name> [--namespace namespace]"
            exit 1
        fi

        echo -e "${BLUE}=== Uninstalling Helm release: $RELEASE_NAME ===${NC}\n"

        helm uninstall "$RELEASE_NAME" "${EXTRA_ARGS[@]}"

        echo -e "\n${GREEN}Release $RELEASE_NAME uninstalled successfully!${NC}"
        ;;

    *)
        echo -e "${RED}Unknown command: $COMMAND${NC}"
        echo "kubectl commands: status, logs, events, resources"
        echo "Helm commands: helm-install, helm-upgrade, helm-status, helm-logs, helm-restart, helm-uninstall"
        exit 1
        ;;
esac
