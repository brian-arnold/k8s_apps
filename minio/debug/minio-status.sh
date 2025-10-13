#!/bin/bash

# Quick assessment without DirectPV plugin
echo "=== Current MinIO State ==="

echo "1. MinIO pods:"
kubectl get pods -n minio-tenant 2>/dev/null || echo "No minio-tenant namespace"

echo -e "\n2. MinIO PVCs:"
kubectl get pvc -n minio-tenant 2>/dev/null || echo "No PVCs in minio-tenant"

echo -e "\n3. DirectPV resources:"
kubectl get directpvdrives.directpv.min.io 2>/dev/null || echo "No DirectPV drives"
kubectl get directpvvolumes.directpv.min.io 2>/dev/null || echo "No DirectPV volumes"

echo -e "\n4. Storage class:"
kubectl get storageclass directpv-min-io 2>/dev/null || echo "DirectPV storage class not found"

echo -e "\n5. Storage nodes taints:"
for node in at-storageos{1..4}; do
  echo -n "$node: "
  kubectl get node $node -o jsonpath='{.spec.taints}' 2>/dev/null | jq -r '.[].key' 2>/dev/null || echo "No taints"
done