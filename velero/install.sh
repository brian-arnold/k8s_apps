helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm repo update
# following the example here: https://github.com/vmware-tanzu/helm-charts/blob/main/charts/velero/README.md#option-2-yaml-file
# their example used --generate-name, but here I specify velero-test as the release name
# helm install [NAME] [CHART] [flags] <-- NAME has to be 'velero', this name is used to name deployments, and the CLI expects the deployment to be named 'velero'

# install with MinIO backend
# helm install velero vmware-tanzu/velero --namespace velero -f ./values_files/values_minio.yaml 

# install with AWS S3 backend
helm install velero vmware-tanzu/velero --namespace velero -f ./values_files/values_aws.yaml
