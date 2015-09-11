## k8s v1.0.4 on CoreOS/flannel at Digital Ocean
Simple bootstrap config for quick start

get latest stable release version number:

```bash
k8s_latest=`curl https://storage.googleapis.com/kubernetes-release/release/stable.txt`

# all binaries can be curled via:
http://storage.googleapis.com/kubernetes-release/release/$k8s_latest/bin/linux/amd64/<binary_name>
```

Revise the yaml files to ensure `kubernetes-release` is as expected.

### Installation
Quick start to set up Kubernetes on CoreOS/flannel at DigitalOcean.

### Todo

* Use DO API

### Create Master Instance

Create a new droplet via DO interface, as follows:
  1. Droplet Hostname: `master.domain.com`
  1. Select Size: Any
  1. Select Region: Any with private networking support
  1. Available Settings: "Private Networking", "Enable User Data"
  1. Put cloud-config to user data textarea
  1. Select Image: CoreOS (stable)
  1. Choose your SSH key
  1. Press "Create a Droplet" button

For Demo: Create DNS record pointing `master.domain.com` to public IP of droplet

### Create Node Instance

Create a new droplet via DO interface, as follows (replace %i% by running number):
  1. Droplet Hostname: `node%i%.domain.com`
  1. Select Size: Any
  1. Select Region: *same region as master*
  1. Available Settings: "Private Networking", "Enable User Data"
  1. Put cloud-config to user data textarea
  1. *Replace `<master-private-ip>` by your master private ip address*
  1. Select Image: CoreOS (stable)
  1. Choose your SSH key
  1. Press "Create a Droplet" button

For Demo: create a DNS record pointing to `node%i%.domain.com` to public IP of droplet

### Testing

* Connect to master `ssh core@%MASTER_DROPLET_EXTERNAL_IP% -i IdentityFile`
* `fleetctl list-machines` 
* `kubectl get cs`
* `kubectl get nodes`

### Run & Expose Kube-ui for demo

```bash
git clone https://github.com/so0k/yapc-asia-2015.git
kubectl create -f yapc-asia-2015.git/demo/rc/kube-ui-rc.yaml --namespace=kube-system
kubectl create -f yapc-asia-2015.git/demo/svc/kube-ui-svc.yaml --namespace=kube-system
```

Once UI pods have started, ui will be available here: `http://master.domain.com:8080/ui/`

