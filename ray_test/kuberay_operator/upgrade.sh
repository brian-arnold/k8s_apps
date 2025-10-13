# this command came from here:
# https://docs.ray.io/en/latest/cluster/kubernetes/k8s-ecosystem/prometheus-grafana.html#step-3-install-a-kuberay-operator
helm upgrade kuberay-operator kuberay/kuberay-operator --version 1.4.2 \
  --set metrics.serviceMonitor.enabled=true \
  --set metrics.serviceMonitor.selector.release=prometheus \
  -n ray