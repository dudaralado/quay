#!/bin/bash
echo "Deploying QUAY"
echo "Please select the Quay version"
#echo "Open a new terminal window and"
#echo "run the following command to see the available tags:"
#echo "skopeo list-tags docker://quay.io/projectquay/quay"
skopeo list-tags docker://quay.io/projectquay/quay
read QUAY_VERSION
sudo sed -i 's/HOSTNAME_FQDN/'$FQDN'/g' $QUAY_CONFIG/config.yaml
sudo podman run -d -p 80:8080 -p 443:8443  \
  --name=quay0 \
  --privileged=true \
  -e DEBUGLOG=true \
  -v $QUAY_CONFIG:/conf/stack:Z \
  -v $QUAY_STORAGE:/datastorage:Z \
  quay.io/projectquay/quay:$QUAY_VERSION
