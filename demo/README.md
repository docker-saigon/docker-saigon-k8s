# Docker Saigon - Intro to Kubernetes

### Pre-Requisites 

1. Create the kubernetes cluster following steps described here: [setup-DigitalOcean](setup-DigitalOcean/README.md)

1. Create an nginx proxy running outside of k8s cluster listening on port 80

1. Create DNS Records pointing `inspect.domain.com` & `canary.domain.com` to the nginx proxy

1. Add nginx load balancing entries for `inspect.domain.com` & `canary.domain.com` as follows:

   `/etc/nginx/conf.d/inspector.conf`
   ```
    upstream inspector {
      least_conn;
      server node0.domain.com:31000;
      server node1.domain.com:31000;
      server node2.domain.com:31000;
    }

    server {
        listen 80;
        server_name  inspect.domain.com;

        location / {
            proxy_pass http://inspector;
        }
    }
   ```

   `/etc/nginx/conf.d/canary-inspector.conf`
   ```
    upstream canary-inspector {
      least_conn;
      server node0.domain.com:31001;
      server node1.domain.com:31001;
      server node2.domain.com:31001;
    }

    server {
        listen 80;
        server_name  canary.domain.com;

        location / {
            proxy_pass http://canary-inspector;
        }
    }
   ```

1. Ensure working directory has demo config files:

   ```
   ssh core@master.domain.com
   ```

   ```
   git clone https://github.com/so0k/yapc-asia-2015.git
   ```

   ```
   cd ~core/yapc-asia-2015/demo/
   ```

### Create the demo namespace

```
kubectl create -f ns/kube-demo-namespace.yaml 
```

```
kubectl config set-context demo --namespace=demo
```

### Confirm namespace exists & context is updated

```
kubectl get namespaces
```

```
kubectl config view
```

### Explore the Kubernetes API

```
kubectl get cs
```

```
kubectl get no
```

```
kubectl get po
```

```
kubectl get rc
```

```
kubectl get svc
```

### Create a Replication Controller

```
kubectl run inspector \
  --labels="app=inspector,track=stable" \
  --image=b.gcr.io/kuar/inspector:1.0.0
```

```
kubectl describe pods inspector
```

### Scale out with kubectl

#### Terminal 1

```
kubectl get pods --watch-only
```

#### Terminal 2

```
kubectl scale rc inspector --replicas=10
```

### Expose the inspector service (using nodePort instead of publicIPs for demo purpose only)

```
cat svc/inspector-svc.yaml
```

```
kubectl get po -l app=inspector
```

```
kubectl create -f svc/inspector-svc.yaml
```

```
kubectl describe svc inspector
```

node0.domain.com:31000

### Expose services with nginx

```
ssh user@domain.com
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

http://inspect.domain.com/net

### The canary deployment pattern

```
kubectl run inspector-canary \
  --labels="app=inspector,track=canary" \
  --replicas=2 \
  --image=b.gcr.io/kuar/inspector:2.0.0
```

```
while true; do curl -s http://inspect.domain.com | \
  grep -o -e 'Version: Inspector [0-9].[0-9].[0-9]'; sleep .5; done
```

#### expose the canary service

```
cat svc/inspector-canary-svc.yaml
```

```
kubectl create -f svc/inspector-canary-svc.yaml
```

```
kubectl describe svc inspector-canary
```

```
kubectl get po -l app=inspector,track=canary
```

```
ssh user@domain.com
```

```
cat /etc/nginx/conf.d/inspector-canary.conf
```

http://canary.domain.com/

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

```
kubectl get pods
```

### Troubleshooting

```
kubectl describe svc inspector-canary
```

```
kubectl get pods -l track=canary
```

```
kubectl label pods <canary-pod> track-
```

```
kubectl describe pods <canary-pod>
```

```
kubectl get pods
```

```
kubectl describe svc inspector-canary
```

```
kubectl logs -f <canary-pod>
```

```
kubectl delete pods <canary-pod>
```

```
kubectl get pods
```

### Rolling update

#### Terminal 1

```
while true; do curl -s http://inspect.domain.com | \
  grep -o -e 'Version: Inspector [0-9].[0-9].[0-9]'; sleep .5; done
```

#### Terminal 2

```
kubectl get pods --watch-only
```

#### Terminal 3

```
kubectl rolling-update inspector --update-period=3s --image=b.gcr.io/kuar/inspector:2.0.0
```

#### Terminal 4

```
kubectl describe pods <inspector-pod>
```

### Cleaning up

```
kubectl delete rc inspector
kubectl delete svc inspector
kubectl delete rc inspector-canary
kubectl delete svc inspector-canary
```