#/bin/bash

if [[ -z "$DO_TOKEN" ]] ; then
	echo "export DO_TOKEN first"
	exit 64
fi

if [[ $# -lt 3 ]]; then 
  echo "Destroy Digital Ocean Droplets"
  echo ""
  echo "  I don't have to tell you this script is used at your own risk!"
  echo ""
	echo "  destroy.sh <domain> <region> <node_count>"
	exit 64
fi

DOMAIN="$1"
REGION="$2"
COUNT="$3"

let "MAX_ID = $3-1"

echo "Destroying CoreOS k8s cluster ---"
echo "--- DOMAIN: $DOMAIN"
echo "--- NODE COUNT: $COUNT (0 - $MAX_ID)"
echo "--- REGION $REGION"
echo "---"
echo ""
echo "Are you sure?"
echo ""
echo "press ENTER to continue or CTRL+C to cancel"
read

echo "destroying nodes.."
for i in `seq 0 ${MAX_ID}`; 
do 
 	HOST="node${i}" 
 	doctl -k $DO_TOKEN d d $HOST.$REGION.$DOMAIN  
done

echo "destroying master"
doctl -k $DO_TOKEN d d master.$REGION.$DOMAIN 