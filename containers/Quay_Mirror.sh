#!/bin/bash

mkdir -pv "$HOME/QuayDeploy/mirror/quay/config"
mkdir -pv "$HOME/QuayDeploy/mirror/quay/config/extra_ca_certs"
mkdir -pv "$HOME/QuayDeploy/mirror/quay/storage"
mkdir -pv "$HOME/QuayDeploy/mirror/postgres-quay"


export MIRROR_QUAY_CONFIG=$HOME/QuayDeploy/mirror/quay/config
export MIRROR_QUAY_STORAGE=$HOME/QuayDeploy/mirror/quay/storage
export MIRROR_QUAY_HAProxy=$HOME/Quay/mirror/configs
export MIRROR_Quay_Certs=$HOME/Quay/mirror/ssl_certs
export MIRROR_QUAY_POSTGRE=$HOME/QuayDeploy/mirror/postgres-quay


echo "Enter the FQDN of you mirror registry"
read MIRROR_FQDN

export FQDN=$MIRROR_FQDN

sudo cat ./configs/quay_config_simple.yaml > $MIRROR_QUAY_CONFIG/config.yaml
sleep 10

sudo sed -i 's/HOSTNAME_FQDN/'$FQDN'/g' $MIRROR_QUAY_CONFIG/config.yaml
sudo sed -i 's/5432/5434/g' $MIRROR_QUAY_CONFIG/config.yaml
sudo sed -i 's/6379/6380/g' $MIRROR_QUAY_CONFIG/config.yaml
sudo sed -i 's/FEATURE_REPO_MIRROR: false/FEATURE_REPO_MIRROR: true/g' $MIRROR_QUAY_CONFIG/config.yaml

echo "Deploying Redis"
sleep 5
sudo podman run -d  --name redis-mirror \
        -e DEBUGLOG=true   \
        -p 6380:6379 \
        docker.io/library/redis:latest \
        --requirepass strongpassword

echo "Deploying Quay Postgre"
sleep 5
sudo podman run -d --name postgresql-quay-mirror  \
        -e DEBUGLOG=true   \
        -e POSTGRES_USER=quay \
        -e POSTGRES_PASSWORD=pass \
        -e POSTGRES_DB=quay \
        -p 5434:5432 \
        -v $MIRROR_QUAY_POSTGRE:/var/lib/postgresql/data:Z \
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

echo "Deploying QUAY"
sudo sed -i 's/HOSTNAME_FQDN/'$FQDN'/g' $MIRROR_QUAY_CONFIG/config.yaml
sudo podman run -d -p 8084:8080 -p 8446:8443  \
  --name=quay3 \
  --privileged=true \
  -e DEBUGLOG=true \
  -v $MIRROR_QUAY_CONFIG:/conf/stack:Z \
  -v $MIRROR_QUAY_STORAGE:/datastorage:Z \
  -v /etc/hosts:/etc/hosts:Z \
    quay.io/projectquay/quay:latest

sleep 20

  echo " Deploying mirroring"
  sudo podman run -d --name mirroring-worker-mirror \
    -v $MIRROR_QUAY_CONFIG:/conf/stack:Z \
    -v /etc/hosts:/etc/hosts:Z \
    quay.io/projectquay/quay:latest repomirror

sleep 40

curl -X POST -k  http://$FQDN:8084/api/v1/user/initialize --header 'Content-Type: application/json' --data '{ "username": "quayadmin", "password": "quayadmin", "email": "quayadmin@$FQDN", "access_token": true}'
