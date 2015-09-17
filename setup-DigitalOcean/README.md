## k8s v1.0.4 on CoreOS/flannel at Digital Ocean

Simple bootstrap config for quick start

get latest stable kubernetes release version number:

```bash
k8s_latest=`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`

# all stable kubernetes binaries can then be curled via:
http://storage.googleapis.com/kubernetes-release/release/$k8s_latest/bin/linux/amd64/<binary_name>
```

Revise the yaml files to ensure `kubernetes-release` is as expected (this repo version uses 1.0.4).

### Digital Ocean API Key

You will need your Digital Ocean API key handy. Head over to https://cloud.digitalocean.com/settings/applications if you do not yet have one. Generate a new *Personal Access Token* for both *read* and *write*. Export the token as an environment variable so we can use it later on:

```console
$ export DO_TOKEN=<token_from_website>
```

### Using doctl

[`doctl`](https://github.com/digitalocean/doctl/) is a tool written in Go to simplify Digital Ocean control from the command line. Below are a few scripts using doctl to set up & tear down a Kubernetes cluster on Digital Ocean.

The Start script will detect if doctl is available and download doctl 0.0.16 if not found.

All scripts also depend on [jq](https://stedolan.github.io/jq/) but do not detect if it is missing.

`jq` comes pre-installed on CoreOS, if you need to pull v1.5 to your local machine (assuming linux x86_64):

```console
$ sudo curl -sLo /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
$ sudo chmod +x /usr/bin/jq
```

The Scripts do not store any configuration of the cluster created and are pretty dumb, would like to move to terraform in future.

**NOTE**: Be very careful with the script to destroy droplets, do not run unless you understand how it works!

#### Script: start.sh

##### Usage:

```console
$ ./scripts/create.sh <domain> <region> <nodes>
```

for example, the following command will create **3 nodes** (1 master + 2 workers) for domain.com in Singapore region

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

### Digital Ocean caveats:

Notice that the default interface `eth0` receives 2 IP addresses:

```console
$ ip -4 addr show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    inet 169.254.171.147/16 brd 169.254.255.255 scope link eth0
       valid_lft forever preferred_lft forever
    inet 188.166.243.236/20 brd 188.166.255.255 scope global eth0
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    inet 10.130.50.203/16 brd 10.130.255.255 scope global eth1
       valid_lft forever preferred_lft forever
4: flannel.1@NONE: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN group default
    inet 10.244.40.0/16 scope global flannel.1
       valid_lft forever preferred_lft forever
5: docker0@NONE: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default
    inet 10.244.40.1/24 scope global docker0
       valid_lft forever preferred_lft forever
```

This trips up `kelseyhightower\network-environment-setup` which picks up the first ip address (internal) for `${DEFAULT_IPV4}` as the Host Name reported by the kubelet, causing several issues with the k8s cluster.

[From DO CoreOS troubleshooting guide](https://www.digitalocean.com/community/tutorials/how-to-troubleshoot-common-issues-with-your-coreos-servers#checking-for-access-to-the-metadata-service): The actual cloud-config file that is given when the CoreOS server is created with DigitalOcean is stored using a metadata service. The Meta Data service lives in CIDR `196.254.0.0/16` which is routed through `eth0`.

From within your host machine, type:

```console
$ curl -L 169.254.169.254/metadata/v1
id
hostname
user-data
vendor-data
public-keys
region
interfaces/
dns/

$ curl -L 169.254.169.254/metadata/v1/user-data
#cloud-config
users:
...
```

We can fix in 3 ways:

1. Use the [`cgeoffroy/setup-network-environment`](https://github.com/cgeoffroy/setup-network-environment/commit/b09605e88c9bcc6d10bc442f6dd829ae317d488a) fork which comes with a `-f option to filter CIDR` use this option to filter out `196.254.0.0/16`
1. Use `$public_ipv4` variable which is made available to the cloud-config
1. Use `$private_ipv4` variable which is made avaialble to the cloud-config

I chose option 1 to keep functionality the same as in original yaml files but make them work on Digital Ocean, this should be the same as `$public_ipv4` - which exposes cAdvisor statistics to the public internet. I believe using `$private_ipv4` is a better option.

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
  $ curl -X GET "https://api.digitalocean.com/v2/droplets/<master_id>"   -H "Authorization: Bearer $DO_TOKEN" -s | jq -r '.droplet.networks.v4[] | select(.type == "private") |  .ip_address'
  10.44.48.24
  $ export MASTER_PRIVATE_IP=10.44.48.24
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
      "user_data": "'"$(cat cloud-init-node.yaml | sed "s/<master-private-ip>/${MASTER_PRIVATE_IP}/g" | sed 's/"/\\"/g')"'"
  }
  ```

#### List all Droplets

```
curl -X GET "https://api.digitalocean.com/v2/droplets" \
  -H "Authorization: Bearer $DO_TOKEN" | jq .
```