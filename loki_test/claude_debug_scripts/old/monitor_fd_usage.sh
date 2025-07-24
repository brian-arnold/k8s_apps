#!/bin/bash

echo "=== Monitoring file descriptor usage across cluster ==="

# Function to get detailed FD usage for a node
get_node_fd_details() {
    local node=$1
    echo "=== Node: $node ==="
    
    kubectl debug node/$node -it --image=busybox --restart=Never --rm -- sh -c "
        echo 'System FD stats:'
        cat /proc/sys/fs/file-nr
        echo 'Format: allocated, unused, maximum'
        echo ''
        
        echo 'Top 15 processes by file descriptor count:'
        echo 'FD_COUNT PID COMMAND'
        (
            for pid in \$(ls /proc/ | grep '^[0-9]*\$'); do
                if [ -d \"/proc/\$pid/fd\" ]; then
                    count=\$(ls \"/proc/\$pid/fd\" 2>/dev/null | wc -l)
                    if [ \$count -gt 5 ]; then
                        comm=\$(cat \"/proc/\$pid/comm\" 2>/dev/null || echo 'unknown')
                        cmdline=\$(cat \"/proc/\$pid/cmdline\" 2>/dev/null | tr '\0' ' ' | cut -c1-50)
                        echo \"\$count \$pid \$comm \$cmdline\"
                    fi
                fi
            done
        ) | sort -rn | head -15
        
        echo ''
        echo 'Checking for processes with many inotify watches:'
        (
            for pid in \$(ls /proc/ | grep '^[0-9]*\$'); do
                if [ -f \"/proc/\$pid/fdinfo/3\" ]; then
                    inotify_count=\$(grep -c 'inotify' \"/proc/\$pid/fdinfo/\"* 2>/dev/null || echo 0)
                    if [ \$inotify_count -gt 0 ]; then
                        comm=\$(cat \"/proc/\$pid/comm\" 2>/dev/null || echo 'unknown')
                        echo \"\$inotify_count \$pid \$comm\"
                    fi
                fi
            done
        ) | sort -rn | head -10
    " 2>/dev/null || echo "Failed to debug node $node"
}

# Check a few representative nodes
echo "Checking file descriptor usage on key nodes..."

# Check master node
get_node_fd_details "at-kubemaster1"

# Check a compute node with many pods
get_node_fd_details "at-compute011"

# Check a GPU node
get_node_fd_details "at-gpu11"

echo ""
echo "=== Looking for container processes specifically ==="

# Try to correlate high FD usage with container processes
kubectl get pods --all-namespaces -o wide | grep -E "(loki|alloy|prometheus|grafana)" | while read namespace pod _ _ _ _ node _; do
    echo "Checking $namespace/$pod on $node..."
    
    # Get the container ID or process info
    kubectl describe pod "$pod" -n "$namespace" | grep -E "Container ID|Process ID" || true
done