## k8s v1.0.4 on CoreOS/flannel at Digital Ocean

Simple bootstrap config for quick start

get latest stable release version number:

```bash
k8s_latest=`curl https://storage.googleapis.com/kubernetes-release/release/stable.txt -s`

# all kubernetes binaries can be curled via:
http://storage.googleapis.com/kubernetes-release/release/$k8s_latest/bin/linux/amd64/<binary_name>
```

Revise the yaml files to ensure `kubernetes-release` is as expected (this repo version = 1.0.4).

### Installation
Quick start to set up Kubernetes on CoreOS/flannel at DigitalOcean.

### Digital Ocean API Key

You will need your Digital Ocean API key handy. Head over to https://cloud.digitalocean.com/settings/applications if you do not yet have one. Generate a new *Personal Access Token* for both *read* and *write*. Export the token as an environment variable so we can use it later on:

```console
$ export DO_TOKEN=<token_from_website>
```

### Using doctl

[`doctl`](https://github.com/digitalocean/doctl/) is a tool written in Go to simplify Digital Ocean control from the command line. Below are a few scripts using doctl to set up & tear down a Kubernetes cluster on Digital Ocean.

The Start script will detect if doctl is available and download doctl 0.0.16 if not found.

All scripts also depend on [jq](https://stedolan.github.io/jq/) but do not detect if it is missing.

The Scripts do not store any configuration of the cluster created and are pretty dumb.

Be very careful with the script to destroy droplets, do not run unless you understand how it works!

#### Script: start.sh

##### Usage:

```console
$ ./scripts/create.sh <domain> <region> <nodes>
```

for example, the following command will create *3 nodes* (1 master + 2 workers) for domain.com in Singapore region

```console
$ ./scripts/create.sh domain.com sgp1 2
```

#### Script: addnodes.sh

##### Usage:

```console
$ ./scripts/addnodes.sh <domain> <region> <existing_count> <nodes_to_add>
```

for example, the following command will add 2 nodes (node3 & node4) for domain.com in Singapore regaion

```console
$ ./scripts/addnodes.sh domain.com sgp1 3 2
```

#### Script: destroy.sh

##### Usage:

*Danger*

```console
$ ./scripts/destroy.sh <domain> <region> <nodes>
```

for example, the following command will try to destroy master.sgp1.domain.com, node0.sgp1.domain.com & node1.sgp1.domain.com

```console
$ ./scripts/destroy.sh domain.com sgp1 2
```

### Test Cluster

Once the kubernetes cluster has been created, you can test the cluster with following commands

* Connect to master, download kubectl

  ```
  curl -sLo kubectl http://storage.googleapis.com/kubernetes-release/release/v1.0.4/bin/linux/amd64/kubectl
  chmod +x kubectl
  sudo mv kubectl /opt/bin/kubectl
  ```

* `fleetctl list-machines` 
* `kubectl get cs`
* `kubectl get nodes`

### Run & Expose Kube-ui for demo

```bash
git clone https://github.com/so0k/yapc-asia-2015.git
kubectl create -f yapc-asia-2015/demo/rc/kube-ui-rc.yaml --namespace=kube-system
kubectl create -f yapc-asia-2015/demo/svc/kube-ui-svc.yaml --namespace=kube-system
```

Once UI pods have started, UI will be available here: http://master.domain.com:8080/ui/

### Create cluster using Digital Ocean web Interface

Booo!

#### Create Master Droplet

Create a new droplet via DO web interface, as follows:
  1. Droplet Hostname: `master.domain.com`
  1. Select Size: Any
  1. Select Region: Any with private networking support
  1. Available Settings: "Private Networking", "Enable User Data"
  1. Put cloud-config to user data textarea
  1. Select Image: CoreOS (stable)
  1. Choose your SSH key
  1. Press "Create a Droplet" button

For Demo: Create DNS record pointing `master.domain.com` to public IP of droplet

#### Create Node Droplets

Create a new droplets via DO web interface, as follows (replace %i% by running number):
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

### Using Curl & Digital Ocean (API)

Hardcore?

### Get all SSH Keys

Get Id of SSH Keys added to your account using [jq](https://stedolan.github.io/jq/)

```
curl -X GET "https://api.digitalocean.com/v2/account/keys" /
 -H 'Content-Type: application/json' 
 -H "Authorization: Bearer $DO_TOKEN"  -s | jq .
{
  "ssh_keys": [
    {
      "id": 418602,
      "fingerprint": "...",
      "public_key": "ssh-rsa ...",
      "name": ".."
    },
    {
      "id": 721599,
      "fingerprint": "...",
      "public_key": "...",
      "name": "..."
    }
  ],
  "links": {},
  "meta": {
    "total": 2
  }
}
```

```console
$ export SSH_KEY_ID=721599
```

#### Create Master Droplet - untested

  ```
  curl -X POST https://api.digitalocean.com/v2/droplets \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $DO_TOKEN" \
      -d '
  {
      "name":"master.domain.com",
      "region":"sgp1",
      "size":"512mb",
      "image":"coreos-stable",
      "ssh_keys":['$SSH_KEY_ID'],
      "backups":false,
      "private_networking":true,
      "user_data": "'"$(cat cloud-init-master.yaml | sed 's/"/\\"/g')"'"
  }
  ```

  Get master private IP

  ```console
  $ curl -X GET "https://api.digitalocean.com/v2/droplets/<master_id>"   -H "Authorization: Bearer $DO_TOKEN" -s | jq '.droplet.networks.v4'
  [
    {
      "ip_address": "10.130.47.24",
      "netmask": "255.255.0.0",
      "gateway": "10.130.1.1",
      "type": "private"
    },
    {
      "ip_address": "188.166.250.205",
      "netmask": "255.255.240.0",
      "gateway": "188.166.240.1",
      "type": "public"
    }
  ]
  $ export MASTER_PRIVATE_IP=10.130.47.24
  ```

#### Create Node Droplets - untested

  ```console
  curl -X POST https://api.digitalocean.com/v2/droplets \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $DO_TOKEN" \
      -d '
  {
      "name":"master.domain.com",
      "region":"sgp1",
      "size":"512mb",
      "image":"coreos-stable",
      "ssh_keys":['$SSH_KEY_ID'],
      "backups":false,
      "private_networking":true,
      "user_data": "'"$(cat cloud-init-node.yaml | sed 's/<master-private-ip>/$MASTER_PRIVATE_IP/g' | sed 's/"/\\"/g')"'"
  }
  ```

#### List all Droplets

```
curl -X GET "https://api.digitalocean.com/v2/droplets" \
  -H "Authorization: Bearer $DO_TOKEN" | jq .
```