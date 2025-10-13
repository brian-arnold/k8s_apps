# kubectl run kuberay-dashboard --image=quay.io/kuberay/dashboard:v1.4.2 --namespace=ray

helm repo add kuberay https://ray-project.github.io/kuberay-helm/
helm repo update
helm install kuberay-apiserver kuberay/kuberay-apiserver --version v1.4.2 --set security= --set cors.allowOrigin='*' --namespace ray
