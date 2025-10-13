Following these instructions [here](https://docs.ray.io/en/latest/cluster/kubernetes/user-guides/kuberay-dashboard.html)

kubectl apply -f kuberay-dashboard-secure-ingress.yaml

kubectl delete ingress kuberay-dashboard-ingress-secure -n ray
