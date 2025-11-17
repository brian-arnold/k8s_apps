There appear to be two helm charts to potentially use. One is in the nocodb github repo here:

```
https://github.com/nocodb/nocodb/tree/develop/charts/nocodb
```

The other is in a personal repo here, which we went with for starters:

```
https://github.com/zekker6/helm-charts/tree/main/charts/apps/nocodb
```

While I'm not sure which one is best, giving the values files to claude showed that in the personal repo, there is a comment saying that it inherits from the k8s common library which often means better Kubernetes best practices, more configurability, and cleaner templates.

The default chart values for the k8s common library can be found here:
```
https://github.com/zekker6/helm-charts/blob/main/charts/library/common/values.yaml
```