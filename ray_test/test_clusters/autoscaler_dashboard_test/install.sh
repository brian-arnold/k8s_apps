helm repo add kuberay https://ray-project.github.io/kuberay-helm/
helm repo update
helm install autoscale-dashboard-test kuberay/ray-cluster --version 1.4.0 -n ray -f ./values.yaml