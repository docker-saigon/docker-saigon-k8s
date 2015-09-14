#/bin/bash

#doctl -k $DO_TOKEN keys
KEYS="digitalocean02"
IMAGE="coreos-alpha"

if ! [ -x "$(command -v doctl)" ]; then
  echo "doctl missing, press ENTER To download or CTRL+C to cancel"
  read

  #get doctl for:
  #   darwin-amd64-doctl.tar.bz2  
  #   linux-amd64-doctl.tar.bz2
  #curl -sL https://github.com/digitalocean/doctl/releases/download/0.0.16/linux-amd64-doctl.tar.bz2 | tar xj -C /usr/bin/ 
  
  #get doctl for:
  #   windows-amd-64-doctl.zip
  echo "Downloading doctl for Windows... "
  curl -sL -o doctl.zip https://github.com/digitalocean/doctl/releases/download/0.0.16/windows-amd-64-doctl.zip
  #ensure 7z is on bash path…
  # ln -s "/C/Program Files/7-Zip/7z.exe" /usr/bin/7z
  #extract to bin folder & remove archive
  7z x doctl.zip -y -o"/usr/bin/" && rm doctl.zip
fi

if [[ -z "$DO_TOKEN" ]] ; then
  echo "export DO_TOKEN first"
  exit 64
fi

if [[ $# -lt 3 ]]; then 
  echo "Provision a Kubernetes cluster on Digital Ocean"
  echo ""
  echo "  This script will provision 1 kubernetes master and <node_count> nodes running $IMAGE with flannel"
  echo ""
	echo "  create.sh <domain> <region> <node_count>"
	exit 64
fi

DOMAIN="$1"
REGION="$2"
COUNT="$3"

let "MAX_ID = $COUNT-1"

echo "Starting CoreOS k8s cluster ---"
echo "--- DOMAIN: $DOMAIN"
echo "--- IMAGE: $IMAGE"
echo "--- SSH KEYS TO ADD: $KEYS"
echo "--- NODE COUNT: $COUNT (0 - $MAX_ID)"
echo "--- REGION $REGION"
echo "---"
echo "press ENTER to continue or CTRL+C to cancel"
read

#create master node
#call doctl to create droplet, and wait for action to complete
echo "Creating Kubernetes Master Droplet... (this could take a while)"
MASTER_DROPLET_JSON=`doctl -f 'json' -k $DO_TOKEN d c -d $DOMAIN -i "$IMAGE" -s "512mb" -r "$REGION" -p -k $KEYS -uf configs/cloud-init-master.yaml --wait-for-active master`
echo "Droplet Created."

#get droplet name
MASTER_DROPLET_NAME=`echo $MASTER_DROPLET_JSON | jq -r .name`

#debugging strings:
#echo $MASTER_DROPLET_JSON | jq .
#echo "press ENTER to continue or CTRL+C to cancel"
#read

#loop until master public ip is known
while [[ -z "$MASTER_PUBLIC_IP" ]]
do
  MASTER_DROPLET_JSON=`doctl -f 'json' -k $DO_TOKEN droplet find $MASTER_DROPLET_NAME`

  #parse master droplet json with jq, use -r flag to return raw ip_addresses
  MASTER_PRIVATE_IP=`echo $MASTER_DROPLET_JSON | jq -r '.networks.v4[] | select(.type == "private") | .ip_address'`
  MASTER_PUBLIC_IP=`echo $MASTER_DROPLET_JSON | jq -r '.networks.v4[] | select(.type == "public")  | .ip_address'`

  if [[ -z "$MASTER_PUBLIC_IP" ]]; then 
    #sleep 2 seconds
    sleep 2
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
for i in `seq 0 ${MAX_ID}`; 
do 
 	HOST="node${i}" 
 
 	echo "Creating ${HOST} Droplet..." 
 	doctl -f 'json' -k $DO_TOKEN d c -d $DOMAIN -i "coreos-alpha" -s "512mb" -r "$REGION" -p -k $KEYS -u="${NODE_USERDATA}" $HOST | jq .
  echo "Request sent." 
done

echo "Script finished, k8s node Droplets may take a while to come online... - be patient -"
echo "Connect to k8s master:"
echo "         ssh -i ~/.ssh/id_digitalocean core@$MASTER_PUBLIC_IP"
echo "k8s ui:"
echo "         http://$MASTER_PUBLIC_IP:8080/ui/"

#todo, generate .kubeconfig pointing to $MASTER_PUBLIC_IP