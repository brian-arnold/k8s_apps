# it is recommended to first uninstall clusters before the operator
# https://discuss.ray.io/t/best-practise-for-taking-down-ray-cluster-deployments-on-kubernetes/6110
helm uninstall raycluster-1 -n ray
helm uninstall raycluster-2 -n ray
helm uninstall  kuberay-operator -n ray
kubectl delete namespace ray