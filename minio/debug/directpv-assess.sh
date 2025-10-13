#!/bin/bash

# DirectPV and MinIO Recovery Assessment Script
set -e

echo "=== DirectPV and MinIO Recovery Assessment ==="
echo ""

# Check DirectPV namespace and pods
echo "1. DirectPV Pod Status:"
echo "----------------------"
kubectl get pods -n directpv -o wide

echo -e "\n2. DirectPV Drives Status:"
echo "-------------------------"
kubectl directpv list drives

echo -e "\n3. DirectPV Volumes Status:"
echo "---------------------------"
kubectl directpv list volumes

echo -e "\n4. Storage Nodes Status:"
echo "------------------------"
for node in at-storageos1 at-storageos2 at-storageos3 at-storageos4; do
    echo "Node: $node"
    kubectl describe node $node | grep -E "(Taints:|Ready)"
    echo ""
done

echo -e "\n5. MinIO Namespace Status:"
echo "-------------------------"
kubectl get all -n minio-tenant 2>/dev/null || echo "MinIO tenant namespace not found"

echo -e "\n6. MinIO PVC Status:"
echo "-------------------"
kubectl get pvc -n minio-tenant 2>/dev/null || echo "No PVCs found"

echo -e "\n7. Available DirectPV Storage Classes:"
echo "-------------------------------------"
kubectl get storageclass | grep directpv

echo -e "\n8. Recent Events (DirectPV and MinIO):"
echo "--------------------------------------"
kubectl get events --all-namespaces | grep -E "(directpv|minio)" | tail -10

echo -e "\n=== Assessment Complete ==="