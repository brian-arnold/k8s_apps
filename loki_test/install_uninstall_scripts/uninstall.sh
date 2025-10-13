# UNINSTALL LOKI
helm uninstall loki -n loki
kubectl delete namespace loki  # This removes any remaining resources

# UNINSTALL ALLOY
helm uninstall alloy -n alloy
kubectl delete namespace alloy

# DO NOT RUN THESE!
# kubectl delete pvc --all -n loki
# kubectl delete pv --all -n loki