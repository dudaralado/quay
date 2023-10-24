#!/bin/bash

mkdir -pv "$HOME/QuayDeploy/clairv4/config"

export CLAIRV4_CONFIG=$HOME/QuayDeploy/clairv4/config
setfacl -m u:26:-wx $CLAIRV4_CONFIG

sudo sed -i '/^SECURITY_SCANNER_INDEXING_INTERVAL/a SECURITY_SCANNER_V4_PSK: NmEwOGU5NDBqODU5' $QUAY_CONFIG/config.yaml
sudo sed -i '/^SECURITY_SCANNER_INDEXING_INTERVAL/a SECURITY_SCANNER_V4_ENDPOINT: http://HOSTNAME_FQDN:8081' $QUAY_CONFIG/config.yaml


sudo sed -i 's/FEATURE_SECURITY_SCANNER: false/FEATURE_SECURITY_SCANNER: true/g' $QUAY_CONFIG/config.yaml
sudo cat ./configs/clairv4-config.yaml > $CLAIRV4_CONFIG/config.yaml
sudo sed -i 's/HOSTNAME_FQDN/'$FQDN'/g' $CLAIRV4_CONFIG/config.yaml

echo "Please select the Clair version"
#echo "Open a new terminal window and"
#echo "run the following command to see the available tags:"
#echo "skopeo list-tags docker://quay.io/projectquay/clair"
skopeo list-tags docker://quay.io/projectquay/clair
read CLAIR_VERSION

if [ "$SSL" == "y" ]; then
echo "Deploying Clair with TLS Certificates"
sleep 5
sudo podman run -d --name clairv4 \
  -p 8081:8081 -p 8089:8089 \
  -e CLAIR_CONF=/clair/config.yaml \
  -e CLAIR_MODE=combo \
  -v $Quay_Certs/rootCA.cert:/run/certs/ca.crt:Z \
  -v $CLAIRV4_CONFIG:/clair:Z \
  quay.io/projectquay/clair:$CLAIR_VERSION
else
  echo "Deploying Clair"
  sleep 5
  sudo podman run -d --name clairv4 \
    -p 8081:8081 -p 8089:8089 \
    -e CLAIR_CONF=/clair/config.yaml \
    -e CLAIR_MODE=combo \
    -v $CLAIRV4_CONFIG:/clair:Z \
    quay.io/projectquay/clair:$CLAIR_VERSION
fi
#  -v $QUAY_STORAGE:/datastorage:Z \
