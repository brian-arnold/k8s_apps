VALS_DIR=/mnt/lab/users/barnold/k8s_apps/nocodb_test/values

helm repo add zekker6 https://zekker6.github.io/helm-charts/
helm repo update
helm install nocodb zekker6/nocodb -f $VALS_DIR/values.yaml -n nocodb --create-namespace