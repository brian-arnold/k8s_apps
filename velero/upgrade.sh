# example taken from here: https://github.com/vmware-tanzu/helm-charts/blob/main/charts/velero/README.md#upgrade-the-configuration
# helm upgrade velero vmware-tanzu/velero --namespace velero -f ./values_files/values_minio.yaml
helm upgrade velero vmware-tanzu/velero --namespace velero -f ./values_files/values_aws.yaml