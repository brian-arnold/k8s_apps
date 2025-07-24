# Find pods with fsnotify errors
kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' | while read ns pod; do
    if kubectl logs $pod -n $ns --tail=100 2>/dev/null | grep -q "failed to create fsnotify watcher"; then
        echo "ERROR in $ns/$pod"
        kubectl logs $pod -n $ns --tail=5 | grep "fsnotify"
    fi
done