#!/bin/bash
sh ./containers/packages.sh

sudo podman rm --all -f

sudo rm -rfv $HOME/QuayDeploy/*

mkdir -pv "$HOME/QuayDeploy/quay/config"
mkdir -pv "$HOME/QuayDeploy/quay/config/extra_ca_certs"
mkdir -pv "$HOME/QuayDeploy/quay/storage"


export QUAY_CONFIG=$HOME/QuayDeploy/quay/config
export QUAY_STORAGE=$HOME/QuayDeploy/quay/storage
export QUAY_HAProxy=$HOME/Quay/configs
export Quay_Certs=$HOME/Quay/ssl_certs

sudo setfacl -m u:1001:-wx $QUAY_STORAGE

echo "Please enter the host FQDN"
echo "e.g. bastion.com or bastion.local.lab"
read host_FQDN

#echo $FQDN2 > ./fqdn.txt

export FQDN=$host_FQDN
export IP=$(ip a |grep -A 3 -Ew "(wl.*)|(en.*)"|grep -Ew "inet"|cut -d " " -f 6|cut -d "/" -f 1)

for i in $IP; do sudo echo "$i $FQDN" >> ./hosts;done
#cat hosts
export hosts_etc=$(cat hosts)
#export host_cert=$(cat fqdn.txt|cut -d "." -f 1)
export host_cert=$(echo $FQDN|cut -d "." -f 1)
export wild_card=$(echo $FQDN|cut -d "." -f2-)

#echo $host_cert
#echo $wild_card

#sleep 5

echo "#############################################"
echo "#    Please open another terminal and       #"
echo "# Copy the bellow output on your /etc/hosts #"
echo "#                                           #"
echo "$hosts_etc               "
echo "#############################################"

echo "#############################################"
echo "# The script will wait 60s for you to copy  #"
echo "#############################################"

#sleep 60

#echo "#############################################"
#echo "# Copy the bellow output on your /etc/hosts #"
#echo "#############################################"

mkdir -pv "$HOME/QuayDeploy"

echo "############################"
echo "# Would you like to deplay #"
echo "#  SSL Certificates? (y/n) #"
echo "############################"
read SSL
export SSL=$SSL

echo "################################"
echo "#   Would you like to deplay  #"
echo "#  Quay Conf Container? (y/n) #"
echo "###############################"
read CONF_CONT
export CONF_CONT=$CONF_CONT

echo "##############################"
echo "#  Would you like to deplay #"
echo "#  Clairv4 Container? (y/n) #"
echo "#############################"
read CLAIR_CONT
export CLAIR_CONT=$CLAIR_CONT

echo "###############################"
echo "#  Would you like to deplay  #"
echo "#  S3 Obeject Storage? (y/n) #"
echo "##############################"
read S3_CONT
export S3_CONT=$S3_CONT

echo "##############################"
echo "#  Would you like to deplay #"
echo "#   Quay in HA mode ? (y/n) #"
echo "#############################"
read HA_CONT
export HA_CONT=$HA_CONT

if [ "$SSL" == "y" ]; then
  sudo cat ./configs/quay_config_simple.yaml > $QUAY_CONFIG/config.yaml
  sudo sed -i 's/PREFERRED_URL_SCHEME: http/PREFERRED_URL_SCHEME: https/g' $QUAY_CONFIG/config.yaml
  sudo sed -i '/^FEATURE_ACI_CONVERSION/i EXTERNAL_TLS_TERMINATION: false' $QUAY_CONFIG/config.yaml
  echo "Would you like to create RootCA? (n/y)"
  read CA_CREATE
  if [ "$CA_CREATE" == "y" ]; then 
  	sh $Quay_Certs/RootCA_cert.sh
  	sh $Quay_Certs/host_cert.sh
  	for i in cert key ; do sudo cp -v $Quay_Certs/$host_cert.$i $QUAY_CONFIG/ssl.$i ;done
  else 
  	sh $Quay_Certs/host_cert.sh
  	for i in cert key ; do sudo cp -v $Quay_Certs/$host_cert.$i $QUAY_CONFIG/ssl.$i ;done
  fi
  sudo chmod -R 777 $QUAY_CONFIG
  sh ./containers/redis.sh
else
    sudo cat ./configs/quay_config_simple.yaml > $QUAY_CONFIG/config.yaml
    sh ./containers/redis.sh
fi

if [ "$CONF_CONT" == "y" ]; then
  sh ./containers/quay-config.sh
fi

if [ "$CLAIR_CONT" == "y" ]; then
    sh ./containers/clairv4-postgre.sh
    sh ./containers/clairv4.sh
fi

if [ "$S3_CONT" == "y" ]; then
  sh ./containers/minio.sh
fi

if [ "$HA_CONT" == "y" ]; then
  sh ./containers/quay-postgre.sh
  sh ./containers/quay-ha.sh
  sh ./containers/quay-api.sh
else
  sh ./containers/quay-postgre.sh
  sh ./containers/quay.sh
  sh ./containers/quay-api.sh
fi

if [ "$SSL" == "y" ] ;then
  sleep 60
  #curl -X POST -k  https://$FQDN:$QUAY_PORT/api/v1/user/initialize --header 'Content-Type: application/json' --data '{ "username": "quayadmin", "password": "quayadmin", "email": "quayadmin@$FQDN", "access_token": true}'
  #sleep 10
  curl -X POST -k  https://$FQDN/api/v1/user/initialize --header 'Content-Type: application/json' --data '{ "username": "quayadmin", "password": "quayadmin", "email": "quayadmin@'$FQDN'", "access_token": true}'
  #sleep 10
  echo "loging to the registry"
  #podman login -u quayadmin -p quayadmin $FQDN:$QUAY_PORT #--tls-verify=false --log-level=debug
  #sleep 15
  podman login -u quayadmin -p quayadmin $FQDN #--tls-verify=false --log-level=debug
  #sleep 15
  #echo ""
  #echo ""
  #podman pull busybox
  #podman tag docker.io/library/busybox:latest $FQDN/quayadmin/busybox:latest
  #podman push $FQDN/quayadmin/busybox:latest
  podman pull fedora
  podman tag registry.fedoraproject.org/fedora  $FQDN/quayadmin/fedora:latest
  podman push $FQDN/quayadmin/fedora:latest

sleep 25

curl -X GET -H "Content-Type: application/json" -u "quayadmin:quayadmin" "https://$FQDN/api/v1/repository/quayadmin/fedora/manifest/sha256:158d1c036343866773afa7a7d0412f1479f2f78b881d59528ce61fd29a11e95f/security?vulnerabilities=true"|jq |head
  #sudo podman logs quay0 > quay0.log
  #sudo podman logs quay1 > quay1.log
#  rm -rfv $Quay_Certs/{host,wild_card,fqdn}.txt
else
  sleep 60

  #curl -X POST -k  https://$FQDN:$QUAY_PORT/api/v1/user/initialize --header 'Content-Type: application/json' --data '{ "username": "quayadmin", "password": "quayadmin", "email": "quayadmin@$FQDN", "access_token": true}'
  #sleep 10

  curl -X POST -k  http://$FQDN/api/v1/user/initialize --header 'Content-Type: application/json' --data '{ "username": "quayadmin", "password": "quayadmin", "email": "quayadmin@$FQDN", "access_token": true}'
  #sleep 10

  echo "loging to the registry"
  #podman login -u quayadmin -p quayadmin $FQDN:$QUAY_PORT #--tls-verify=false --log-level=debug
  #sleep 15

  podman login -u quayadmin -p quayadmin $FQDN --tls-verify=false #--log-level=debug
  #sleep 15

  podman pull fedora
  podman tag registry.fedoraproject.org/fedora  $FQDN/quayadmin/fedora:latest
  podman push $FQDN/quayadmin/fedora:latest --tls-verify=false

  sleep 25
  if [ "$CLAIR_CONT" == "y" ]; then
  curl -X GET -H "Content-Type: application/json" -u "quayadmin:quayadmin" "http://$FQDN/api/v1/repository/quayadmin/fedora/manifest/sha256:158d1c036343866773afa7a7d0412f1479f2f78b881d59528ce61fd29a11e95f/security?vulnerabilities=true"|jq |head
  fi
fi

echo "Please select the Quay version"
skopeo list-tags docker://quay.io/projectquay/quay
read QUAY_VERSION

if [ "$SSL" == "y" ] ;then
  echo " Deploying mirroring"
  sudo podman run -d --name mirroring-worker \
  -v $QUAY_CONFIG:/conf/stack:Z \
  -v $Quay_Certs/rootCA.cert:/etc/pki/ca-trust/source/anchors/ca.crt:Z \
  quay.io/projectquay/quay:$QUAY_VERSION repomirror

else
  echo " Deploying mirroring"
  sudo podman run -d --name mirroring-worker \
  -e DEBUGLOG=true \
  -v $QUAY_CONFIG:/conf/stack:Z \
  quay.io/projectquay/quay:$QUAY_VERSION repomirror
fi
rm -rf fqdn.txt ssl.txt hosts

echo "Woudl like extra mirror? (n/y)"
read extra_mirror

if [ "$extra_mirror" == "y" ];then
  sh ./containers/Quay_Mirror.sh
fi
