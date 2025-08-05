clone git repo:
```
git clone https://github.com/unitycatalog/unitycatalog
```
The helm chat can be installed by navigating to the helm subdirectory of that repo. However, because I wanted to customize values, I copied the values file here as `uc-values.yaml`.


create persistent vol for UC
```
kubectl apply -f uc-persistent-volumes.yaml
```

UC wants to write files as a particular user, so I SSH'ed into at-compute003 and did

```
sudo chown -R 100:101 /mnt/md0/uc-data
```


Access the UI
```
kubectl port-forward -n uc service/unitycatalog-ui 3000:3000 &
```
Browse to http://localhost:3000


Some python tips [here](https://github.com/unitycatalog/unitycatalog/tree/main/clients/python/build)
```
from unitycatalog.client import Configuration
```