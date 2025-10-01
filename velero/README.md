Notes to prompt after helm installation:

```
Check that the velero is up and running:

    kubectl get deployment/velero-test -n velero

Check that the secret has been created:

    kubectl get secret/velero-test -n velero

Once velero server is up and running you need the client before you can use it
1. wget https://github.com/vmware-tanzu/velero/releases/download/v1.16.2/velero-v1.16.2-darwin-amd64.tar.gz
2. tar -xvf velero-v1.16.2-darwin-amd64.tar.gz -C velero-client

More info on the official site: https://velero.io/docs
```

Check status after installation
```
kubectl get backupstoragelocation -n velero
```
