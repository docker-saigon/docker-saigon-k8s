#!/bin/bash

#doctl -k $DO_TOKEN keys
KEYS="digitalocean02"
IMAGE="coreos-alpha"
NODE_SIZE="512mb"

if [[ -z "$DO_TOKEN" ]] ; then
  echo "export DO_TOKEN first"
  exit 64
fi

if [[ $# -lt 4 ]]; then 
  echo "Add nodes to a Kubernetes cluster on Digital Ocean"
  echo ""
  echo "  This script will attempt to add <node_count> nodes running $IMAGE with flannel pointing to master"
  echo ""
	echo "  addnodes.sh <domain> <region> <start_count> <node_count>"
	exit 64
fi

DOMAIN="$1"
REGION="$2"
FIRST_ID="$3"
TO_ADD="$4"

let "MAX_ID = $FIRST_ID+$TO_ADD-1"

echo "Upgrading CoreOS k8s cluster ---"
echo "--- DOMAIN: $DOMAIN"
echo "--- IMAGE: $IMAGE"
echo "--- SSH KEYS TO ADD: $KEYS"
echo "--- REGION $REGION"
echo "---"
echo "press ENTER to continue or CTRL+C to cancel"
read

#loop until master public ip is known
while [[ -z "$MASTER_PUBLIC_IP" ]]
do
  MASTER_DROPLET_JSON=`doctl -f 'json' -k $DO_TOKEN droplet find master.$REGION.$DOMAIN`

  #parse master droplet json with jq, use -r flag to return raw ip_addresses
  MASTER_PRIVATE_IP=`echo $MASTER_DROPLET_JSON | jq -r '.networks.v4[] | select(.type == "private") | .ip_address'`
  MASTER_PUBLIC_IP=`echo $MASTER_DROPLET_JSON | jq -r '.networks.v4[] | select(.type == "public")  | .ip_address'`

  if [[ -z "$MASTER_PUBLIC_IP" ]]; then 
    echo "Could not detect public ip of master.$REGION.$DOMAIN - bailing"
    exit 64
  fi
done

echo "Master ---"
echo "--- PUBLIC IP:  $MASTER_PUBLIC_IP"
echo "--- PRIVATE_IP: $MASTER_PRIVATE_IP"
echo "---"
echo "press ENTER to continue or CTRL+C to cancel"
read

#inject master private ip in k8s nodes
NODE_USERDATA=`cat configs/cloud-init-node.yaml | sed "s/<master-private-ip>/${MASTER_PRIVATE_IP}/g"`

#Create kube worker nodes
for i in `seq ${FIRST_ID} ${MAX_ID}`; 
do 
 	HOST="node${i}" 
 
 	echo "Creating ${HOST} Droplet..." 
 	doctl -f 'json' -k $DO_TOKEN d c -d $DOMAIN -i $IMAGE -s "$NODE_SIZE" -r "$REGION" -p -k $KEYS -u="${NODE_USERDATA}" $HOST | jq .
  echo "Request sent." 
done