#!/bin/bash

#export QUAY_CONFIG=$HOME/QuayDeploy/quay/config

export QUAY_CONFIG_MIRROR=$HOME/QuayDeploy/mirror/config
export QUAY_STORAGE_MIRROR=$HOME/QuayDeploy/mirror/storage
export QUAY_POSTGRE_MIRROR=$HOME/QuayDeploy/mirror/postgres-quay

export MIRROR=$HOME/QuayDeploy/mirror

sudo rm -rfv $MIRROR

mkdir -pv "$HOME/QuayDeploy/mirror/config"
mkdir -pv "$HOME/QuayDeploy/mirror/config/extra_ca_certs"
mkdir -pv "$HOME/QuayDeploy/mirror/storage"
mkdir -pv "$HOME/QuayDeploy/mirror/postgres-quay"

echo "Enter the FQDN of you mirror registry"
read MIRROR_FQDN

export FQDN=$MIRROR_FQDN

sudo cat ./configs/quay_config_simple.yaml > $QUAY_CONFIG_MIRROR/config.yaml

sudo sed -i 's/HOSTNAME_FQDN/'$FQDN'/g' $QUAY_CONFIG_MIRROR/config.yaml
sudo sed -i 's/5432/5434/g' $QUAY_CONFIG_MIRROR/config.yaml
sudo sed -i 's/FEATURE_REPO_MIRROR: false/FEATURE_REPO_MIRROR: true/g' $QUAY_CONFIG_MIRROR/config.yaml

echo "Deploying Quay Postgre"
sleep 5

sudo podman run -d --name postgresql-quay-mirror  \
        -e DEBUGLOG=true   \
        -e POSTGRES_USER=quay \
        -e POSTGRES_PASSWORD=pass \
        -e POSTGRES_DB=quay \
        -p 5434:5432 \
        -v $QUAY_POSTGRE_MIRROR:/var/lib/postgresql/data:Z \
        docker.io/library/postgres:latest

sleep 10

echo "Creating extensions"

sudo podman exec -it postgresql-quay-mirror /bin/bash -c 'echo "CREATE EXTENSION IF NOT EXISTS pg_trgm" | psql -d quay -U quay'

echo "Deploying Config"
sleep 5
sudo podman run -d -p 8090:8080  \
  --name=config-mirror \
  -e DEBUGLOG=true \
  quay.io/projectquay/quay:latest  config test123


if [ "$SSL" == "y" ]; then

#sudo cp -v $HOME/Quay/ssl_certs/rootCA.pem $QUAY_CONFIG_MIRROR/extra_ca_certs/

echo "Deploying QUAY"
sudo sed -i 's/HOSTNAME_FQDN/'$FQDN'/g' $QUAY_CONFIG_MIRROR/config.yaml
sudo podman run -d -p 8084:8080 -p 8446:8443  \
  --name=quay3 \
  --privileged=true \
  -e DEBUGLOG=true \
  -v $QUAY_CONFIG_MIRROR:/conf/stack:Z \
  -v $HOME/Quay/ssl_certs:/conf/extra_ca_certs:Z  \
  -v $QUAY_STORAGE_MIRROR:/datastorage:Z \
  -v /etc/hosts:/etc/hosts:Z \
  quay.io/projectquay/quay:latest

sleep 20

echo " Deploying mirroring"
sudo podman run -d --name mirroring-worker \
  -v $QUAY_CONFIG_MIRROR:/conf/stack:Z \
  -v $HOME/Quay/ssl_certs:/conf/extra_ca_certs:Z \
  -v /etc/hosts:/etc/hosts:Z \
  quay.io/projectquay/quay:latest repomirror
else

echo "Deploying QUAY"
sudo sed -i 's/HOSTNAME_FQDN/'$FQDN'/g' $QUAY_CONFIG_MIRROR/config.yaml
sudo podman run -d -p 8084:8080 -p 8446:8443  \
  --name=quay3 \
  --privileged=true \
  -e DEBUGLOG=true \
  -v $QUAY_CONFIG_MIRROR:/conf/stack:Z \
  -v $QUAY_STORAGE_MIRROR:/datastorage:Z \
  -v /etc/hosts:/etc/hosts:Z \
    quay.io/projectquay/quay:latest

sleep 20

  echo " Deploying mirroring"
  sudo podman run -d --name mirroring-worker \
    -e DEBUGLOG=true \
    -v $QUAY_CONFIG_MIRROR:/conf/stack:Z \
    -v /etc/hosts:/etc/hosts:Z \
    quay.io/projectquay/quay:latest repomirror
fi
sleep 40

curl -X POST -k  http://$FQDN:8084/api/v1/user/initialize --header 'Content-Type: application/json' --data '{ "username": "quayadmin", "password": "quayadmin", "email": "quayadmin@$FQDN", "access_token": true}'
