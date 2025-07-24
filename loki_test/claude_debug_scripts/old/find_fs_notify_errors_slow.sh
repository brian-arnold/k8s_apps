#!/bin/bash

echo "=== Searching for fsnotify errors across all pods ==="
echo "This may take a few minutes..."

# Create a temporary file to store results
RESULTS_FILE="/mnt/lab/users/barnold/loki_test/claude_debug_scripts/fsnotify_results_$(date +%s).txt"

# Function to check a single pod
check_pod() {
    local namespace=$1
    local pod=$2
    local container=$3
    
    # Try to get logs and check for fsnotify errors
    if logs=$(kubectl logs "$pod" -n "$namespace" -c "$container" --tail=1000 2>/dev/null); then
        if echo "$logs" | grep -q "failed to create fsnotify watcher: too many open files"; then
            echo "FOUND: $namespace/$pod/$container" >> "$RESULTS_FILE"
            echo "  Error count: $(echo "$logs" | grep -c "failed to create fsnotify watcher")" >> "$RESULTS_FILE"
            echo "  Recent errors:" >> "$RESULTS_FILE"
            echo "$logs" | grep "failed to create fsnotify watcher: too many open files" | tail -3 | sed 's/^/    /' >> "$RESULTS_FILE"
            echo "" >> "$RESULTS_FILE"
        fi
    fi
}

# Get all pods and their containers
kubectl get pods --all-namespaces -o json | jq -r '.items[] | select(.status.phase == "Running") | "\(.metadata.namespace) \(.metadata.name) \(.spec.containers[].name)"' | while read namespace pod container; do
    echo "Checking $namespace/$pod/$container..."
    check_pod "$namespace" "$pod" "$container"
done

echo ""
echo "=== RESULTS ==="
if [ -f "$RESULTS_FILE" ] && [ -s "$RESULTS_FILE" ]; then
    cat "$RESULTS_FILE"
    echo ""
    echo "Full results saved to: $RESULTS_FILE"
else
    echo "No fsnotify errors found in current pod logs."
    echo "The error might be:"
    echo "  1. In older logs that have rotated out"
    echo "  2. In system-level logs (kubelet, containerd)"
    echo "  3. In pods that have restarted"
fi

echo ""
echo "=== Checking for recently restarted pods (might have had the error) ==="
kubectl get pods --all-namespaces -o json | jq -r '.items[] | select(.status.containerStatuses[]?.restartCount > 0) | "\(.metadata.namespace) \(.metadata.name) \(.status.containerStatuses[].restartCount)"' | head -10

echo ""
echo "=== Checking system-level logs for fsnotify errors ==="
echo "Note: This requires access to node system logs"

# Try to check kubelet logs on a few nodes
for node in $(kubectl get nodes -o jsonpath='{.items[0:3].metadata.name}'); do
    echo "Checking kubelet logs on $node..."
    kubectl debug node/$node -it --image=busybox --restart=Never --rm -- sh -c "
        if [ -f /var/log/kubelet.log ]; then
            grep -i 'fsnotify.*too many.*files' /var/log/kubelet.log 2>/dev/null | tail -3
        elif [ -d /var/log/pods ]; then
            find /var/log/pods -name '*.log' -exec grep -l 'fsnotify.*too many.*files' {} \; 2>/dev/null | head -3
        else
            echo 'No kubelet logs found in standard locations'
        fi
    " 2>/dev/null || echo "Could not access system logs on $node"
done