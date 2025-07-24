# Notes

Loki is a database for logs (and a log aggregation system), optimized for storage costs and sifting through logs quickly and handle whatever format the logs come in

Just hand over your logs to loki and define a few labels to use as indices (for database querying), otherwise no need to reconfigure logs

Grafana Alloy is a collector that scrapes logs from applications and sends them to Loki

General installation instructions can be found [here](https://grafana.com/docs/loki/latest/setup/install/).

[Deployment modes](https://grafana.com/docs/loki/latest/get-started/deployment-modes/)

- Monolithic mode runs all of Loki’s microservice components inside a single process as a binary/docker image; this mode is simple and good for quick starts but also works for read/write volumes of up to ~20GB per day, which may be fine for enigma.
- For installing [monolithic loki](https://grafana.com/docs/loki/latest/setup/install/helm/install-monolithic/), we will use a single replica, values.yaml can be found under single replica section.

## Storage

- see [here](https://grafana.com/docs/loki/latest/operations/storage/filesystem/) for comments about using a filesystem object store
    - [here](https://grafana.com/docs/loki/latest/get-started/quick-start/tutorial/#:~:text=Loki-,Configuration,-Grafana%20Loki%20requires) they have some configuration about using filesystem
- they [recommend](https://grafana.com/docs/loki/latest/setup/install/helm/install-monolithic/#:~:text=object%20storage.%20We-,recommend%20configuring%20object%20storage%20via%20cloud%20provider%20or%20pointing%20Loki%20at%20a%20MinIO%20cluster%20for%20production%20deployments.,-Multiple%20Replicas) minio for production environments

I will try to use /mnt/md0 on a worker node to store logging information, on `at-compute003`. We need to have the loki pod consistently launch on this node so that it always has access to the same drive. We can specify this in our `loki-values.yaml` file. However, we may need to give permissions to loki to write here as user `10001`. 

SSH into at-compute003 and:
```
sudo mkdir -p /mnt/md0/loki-data
sudo chown -R 10001:10001 /mnt/md0/loki-data
```

#### Brief background on storage
**StorageClass**: A template that defines what type of storage to create (e.g., SSD, HDD, cloud storage) and how to provision it.
**PersistentVolume (PV)**: The actual storage resource - like a specific disk or storage allocation.
**PersistentVolumeClaim (PVC)**: A request for storage by a pod - specifies how much storage and what type.

How they relate:

- Pod creates a PVC requesting storage
- Kubernetes looks for a PV that matches the PVC requirements
- If no suitable PV exists, the StorageClass automatically creates one
- The PVC gets bound to the PV, and the pod can use the storage

Think of it like: StorageClass = "storage catalog", PV = "actual storage unit", PVC = "storage order form".


It appears you're using the following storage class that was applied a while back:

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: grafana-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: Immediate
```

Because of `no-provisioner`, I have to manually create a PV so that when a PVC requests storage, k8s can find a matching PV in its catalog. This contrasts with dynamic provisioning where StorageClass automatically creates a new PV when a PVC is made.


Typically helm creates the PVCs during installation.

# Loki
## Installation

Installation of loki in monolithic mode, writing to a filesystem instead of a MinIO server, which is better for production environments and perhaps inappropriate for our <1GB of logs per day.


```
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
kubectl apply -f loki-persistent-volumes.yaml
helm install loki grafana/loki -f loki-values.yaml -n loki --create-namespace
```

## Confirm that is works

The following should produce 'OK'
```
kubectl port-forward -n loki svc/loki-gateway 3100:80
curl http://localhost:3100/

```

Check pods
```
kubectl get pods -n loki
```

Check PV and PVC (should be bound)
```
kubectl get pv -n loki
kubectl get pvc -n loki
```

Look at logs
```
kubectl logs -n loki -l app.kubernetes.io/name=loki
```

See helm installation logs to make and fetch a test log (done in separate terminal windows):
```
kubectl port-forward --namespace loki svc/loki-gateway 3100:80

# send test data to loki
curl -H "Content-Type: application/json" -XPOST -s "http://127.0.0.1:3100/loki/api/v1/push"  \
--data-raw "{\"streams\": [{\"stream\": {\"job\": \"test\"}, \"values\": [[\"$(date +%s)000000000\", \"fizzbuzz\"]]}]}" \
-H X-Scope-OrgId:foo

# verify loki received log
curl "http://127.0.0.1:3100/loki/api/v1/query_range" --data-urlencode 'query={job="test"}' -H X-Scope-OrgId:foo | jq .data.result
```

## Debugging

Some of the loki-canary pods, one per node in the DaemonSet to test log ingestion from every node and validate network connectivity, appeared to have issues connecting to the loki-gateway service, looking at the logs of some of the loki-canary pods.

This bash command cycles through all pods looking for connectivity issues:
```
kubectl get pods -n loki -o wide | grep loki-canary | while read pod _ _ _ _ _ node _; do
  timeout_count=$(kubectl logs -n loki $pod --tail=50 2>/dev/null | grep -c "timeout\|failed" || echo "0")
  timeout_count=${timeout_count//[^0-9]/}  # Remove non-numeric characters
  if [ "$timeout_count" -gt 0 ] 2>/dev/null; then
    echo "$node: FAILING ($timeout_count errors)"
  else
    echo "$node: OK"
  fi
done
```
 However, issues with these canaries may not be an issue as the way Alloy sends logs to loki is different.

## Uninstall

```
helm uninstall loki -n loki
kubectl delete pvc --all -n loki
kubectl delete pv --all -n loki
kubectl delete namespace loki  # This removes any remaining resources
```


## Connecting to Grafana

### [Configure Loki](https://grafana.com/docs/grafana/latest/datasources/loki/configure-loki-data-source/)
- Connections -> Data sources -> loki
- connection URL: http://loki-gateway.loki.svc.cluster.local
- HTTP headers
    - Header: X-Scope-OrgID
    - Value: 1

# Alloy
## Alloy installation

Following [this](https://grafana.com/docs/alloy/latest/set-up/install/kubernetes/) guide.

```
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
kubectl create namespace alloy
# helm install --namespace <NAMESPACE> <RELEASE_NAME> grafana/alloy
helm install --namespace alloy alloy grafana/alloy -f alloy-values.yaml
```

The alloy values file ensures logs are being forwarded to loki, and it also excludes a worker node that is unreachable. If this worker node is included, alloy will continue trying to reach it, opening a socket each time, which is bad.

[Here](https://grafana.com/docs/alloy/latest/collect/logs-in-kubernetes/) is a tutorial on configuring loki to collect logs from a variety of sources, and [here](https://grafana.com/docs/alloy/latest/configure/kubernetes/) is a tutorial on how to apply these configurations.

## Verify installation

```
kubectl get pods --namespace alloy -o wide
```

You should see 1 pod per node because it's a DaemonSet.

To confirm the logs are being forwarded:


You should see the following output from the command:
```
>> kubectl exec -n loki pod/loki-0 -c loki -- wget -qO- --header="X-Scope-OrgID: 1" "http://localhost:3100/loki/api/v1/label/job/values"
{"status":"success","data":["loki.source.kubernetes.pods"]}
```

In the Grafana GUI, query `{job="loki.source.kubernetes.pods"}` and set 'Visualizations' to 'Logs'.
## Debugging

At one point, an alloy pod was attempting to reach an unreachable node, each time opening a new socket, which can cause issues. The following code was used to assess the number of open sockets per allow pod:
```
kubectl get pods -n alloy --no-headers | awk '{print $1}' | while read pod; do
  echo -n "$pod: "
  kubectl exec -n alloy $pod -- sh -c 'ls /proc/1/fd 2>/dev/null | wc -l' 2>/dev/null || echo "cannot exec"
done
```

I also made a bash script `monitor-alloy.sh` that prints numerous metrics
## Uninstall

```
helm uninstall alloy -n alloy
kubectl delete namespace alloy
```


# DEBUGGING: failed to create fsnotify watcher: too many open files

The following is a self-contained section also logged as a notion journal.

Background:
- 

Problem: 
- After deploying Alloy and Loki, the following error started popping up in logs, including in those of pods that would fail to run on multiple different machines:  `failed to create fsnotify watcher: too many open files`. 
- Uninstalling Alloy and Loki fixed the problem.
- Interestingly, the system-wide maximum number of file descriptors (seen by running `cat /proc/sys/fs/file-max`) is absurdly large: 9223372036854775807. However, I think the error message is actually misleading, and the real problem is the number of 'inotify instances' and not open files and may be due to the same linux error message being used for multiple problems

Cause:
- An 'fsnotify watcher' is implemented using an 'inotify instance'. An inotify instance is like a "file monitoring session" that a program creates to watch for changes to files or directories (e.g. Loki monitoring logs).
- On multiple worker nodes I ran the following command, which indicated that the max number of inotify instances per linux user ID is 128
```
cat /proc/sys/fs/inotify/max_user_instances
```
- To count the number of inotify instances per user ID, I use the following command:
```
sudo find /proc/*/fd -lname anon_inode:inotify -exec ls -l {} \; 2>/dev/null | awk '{print $3}' | sort | uniq -c | sort -rn
```
- To see which processes own these inotify instances:
```
sudo find /proc/*/fd -lname anon_inode:inotify -exec ls -l {} \; 2>/dev/null | while read line; do
    fd_path=$(echo "$line" | awk '{print $9}')
    pid=$(echo "$fd_path" | cut -d'/' -f3)
    comm=$(cat /proc/$pid/comm 2>/dev/null || echo "unknown")
    owner=$(echo "$line" | awk '{print $3}')
    echo "PID $pid ($comm) - Owner: $owner - FD: $fd_path"
done
```
- There really seem to only be a few users on any node, including those being used by multiple kubernetes namespaces: root, atadmin (b/c I SSH'ed in), systemd-resolve, and nobody.
- Before installing Loki and Alloy, the root seems to have ~65 inotify instances on several nodes. After installation, this number increased to ~130, showing it was maxing out.
- Because kubernetes pods from all namespaces are running processes as the same root user on the worker nodes, we're collectively maxing out the number of inotify instances.

Solution:
- Increase inotify limits using an init container in the Alloy DaemonSet controller. See the alloy-values.yaml file.
- However, this didn't enitrely work b/c the Alloy DaemonSet did not deploy pods to at-compute015 or at-kubemaster1, which both also experienced increases in inotify instances
Miscellaneous:
- The following is the per-user limit for inotify watches only (individual files being monitored), which is 1,003,245:
```
cat /proc/sys/fs/inotify/max_user_watches
```
- When I see how many inotify watches there are across all user IDs, it doesn't really increase after installing Alloy + loki (stayed at 37).
```
sudo find /proc/*/fdinfo/* -exec grep -l inotify {} \; 2>/dev/null | xargs wc -l | tail -1
```