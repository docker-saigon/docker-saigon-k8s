# YAPC 2015 Kubernetes Demo

### Explore the Kubernetes API

```
kubectl get cs
```

```
kubectl get pods
```

```
kubectl get nodes
```

```
kubectl get services
```

### Create a pod

```
kubectl run inspector \
  --labels="app=inspector,track=stable" \
  --image=b.gcr.io/kuar/inspector:1.0.0
```

```
kubectl describe pods inspector
```

#### Scale out with kubectl

```
kubectl scale rc inspector --replicas=10
```

```
kubectl get pods --watch
```

#### Expose the inspector service

```
cat svc/inspector-svc.yaml
```

```
kubectl create -f svc/inspector-svc.yaml
```

```
kubectl describe svc inspector
```

http://104.155.220.199:36000

### Expose services with nginx

```
gcloud compute ssh nginx
```

```
cat /etc/nginx/conf.d/inspector.conf
```

```
sudo docker run -d --net=host \
  -v /etc/nginx/conf.d:/etc/nginx/conf.d \
  nginx
```

```
docker ps
```

http://inspector.kuar.io

### The canary deployment pattern

```
kubectl run inspector-canary \
  --labels="app=inspector,track=canary" \
  --replicas=1 \
  --image=b.gcr.io/kuar/inspector:2.0.0
```

```
while true; do curl -s http://inspector.kuar.io | \
  grep -o -e 'Version: Inspector [0-9].[0-9].[0-9]'; sleep .5; done
```

#### expose the canary service

```
kubectl create -f svc/inspector-canary-svc.yaml
```

```
gcloud compute ssh nginx
```

```
cat /etc/nginx/conf.d/inspector-canary.conf
```

http://canary.inspector.kuar.io

### Self-healing

#### Terminal 1

```
kubectl get pods --watch-only
```

#### Terminal 2

```
kubectl get pods -l track=canary
```

```
kubectl delete pods <canary-pod>
```

### Rolling update

#### Terminal 1

```
while true; do curl -s http://inspector.kuar.io | \
  grep -o -e 'Version: Inspector [0-9].[0-9].[0-9]'; sleep .5; done
```

#### Terminal 2

```
kubectl get pods --watch
```

#### Terminal 3

```
kubectl rolling-update inspector --update-period=3s --image=b.gcr.io/kuar/inspector:2.0.0
```
