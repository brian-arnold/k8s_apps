helm uninstall  kuberay-operator -n ray
helm uninstall raycluster -n ray
kubectl delete namespace ray