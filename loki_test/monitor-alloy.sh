#!/bin/bash
# save as monitor-alloy.sh

echo "=== Alloy Resource Monitoring ==="
echo "Time: $(date)"
echo

kubectl get pods -n alloy --no-headers | while read pod status node; do
  echo "Pod: $pod on Node: $node (Status: $status)"
  
  # File descriptors
  fd_count=$(kubectl exec -n alloy $pod -- sh -c 'ls /proc/1/fd 2>/dev/null | wc -l' 2>/dev/null || echo "N/A")
  echo "  File descriptors: $fd_count"
  
  # Inotify watches
  inotify_count=$(kubectl exec -n alloy $pod -- sh -c 'find /proc/*/fd -lname anon_inode:inotify 2>/dev/null | wc -l' 2>/dev/null || echo "N/A")
  echo "  Inotify watches: $inotify_count"
  
  # Network connections to problematic nodes
  bad_connections=$(kubectl exec -n alloy $pod -- sh -c 'netstat -an 2>/dev/null | grep -E "(172\.26\.102\.159)" | wc -l' 2>/dev/null || echo "N/A")
  echo "  Connections to at-gpu12: $bad_connections"
  
  # Recent errors
  error_count=$(kubectl logs $pod -n alloy --tail=100 --since=5m 2>/dev/null | grep -i "fsnotify\|too many open files\|error" | wc -l)
  echo "  Recent errors (5min): $error_count"
  
  echo
done

# System limits
echo "=== System File Descriptor Usage ==="
echo "Current/Max open files system-wide:"
kubectl debug node/$(kubectl get nodes --no-headers | head -1 | awk '{print $1}') -it --image=busybox -- chroot /host cat /proc/sys/fs/file-nr 2>/dev/null || echo "Cannot check"