DIR=/mnt/lab/users/barnold/loki_test

# INSTALL LOKI
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
kubectl apply -f $DIR/loki-persistent-volumes.yaml
helm install loki grafana/loki -f $DIR/loki-values.yaml -n loki --create-namespace

# INSTALL ALLOY
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
kubectl create namespace alloy
# helm install --namespace <NAMESPACE> <RELEASE_NAME> grafana/alloy
helm install --namespace alloy alloy grafana/alloy -f $DIR/alloy-values.yaml
