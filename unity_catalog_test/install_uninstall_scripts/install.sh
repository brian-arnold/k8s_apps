cd /mnt/lab/users/barnold/k8s_apps/unity_catalog_test/unitycatalog/helm

VAL_DIR=/mnt/lab/users/barnold/k8s_apps/unity_catalog_test
helm install unitycatalog . -n uc --create-namespace -f ${VAL_DIR}/uc-values.yaml