Instructions on KubeRay deployment [here](https://docs.ray.io/en/latest/cluster/kubernetes/getting-started/raycluster-quick-start.html#kuberay-raycluster-quickstart).

Get default values of Ray helm chart:
```
helm repo add kuberay https://ray-project.github.io/kuberay-helm/
helm show values kuberay/ray-cluster --version 1.4.0 > ray-values.yaml
```

Print cluster resources
```
kubectl exec -it raycluster-kuberay-head -n ray -- python -c "import ray; ray.init(); print(ray.cluster_resources())"
```