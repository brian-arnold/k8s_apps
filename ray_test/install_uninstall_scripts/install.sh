VALUES_DIR=/mnt/lab/users/barnold/k8s_apps/ray_test/values

helm repo add kuberay https://ray-project.github.io/kuberay-helm/
helm repo update
helm install kuberay-operator kuberay/kuberay-operator --version 1.4.0 -n ray --create-namespace
helm install raycluster kuberay/ray-cluster --version 1.4.0 -n ray -f ${VALUES_DIR}/ray_cluster_autoscale_values.yaml