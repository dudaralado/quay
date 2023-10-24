echo "Deploying QUAY HA"

sed -i 's/FQDN/'$FQDN'/g' $QUAY_HAProxy/haproxy/haproxy.cfg
sudo sed -i 's/HOSTNAME_FQDN/'$FQDN'/g' $QUAY_CONFIG/config.yaml

if [ "$SSL" == "y" ] ;then
  cat $Quay_Certs/rootCA.cert >> $Quay_Certs/rootCA.pem
  cat $Quay_Certs/rootCA.key >> $Quay_Certs/rootCA.pem

  sudo podman run -d --name my-running-haproxy -p 443:443 -p 80:80 \
  -v $QUAY_HAProxy/haproxy:/usr/local/etc/haproxy:ro \
  -v $Quay_Certs/rootCA.pem:/etc/ssl/certs/rootCA.pem \
  --sysctl net.ipv4.ip_unprivileged_port_start=0 haproxy:2.4
else
sudo podman run -d --name my-running-haproxy -p 443:443 -p 80:80 \
-v $QUAY_HAProxy/haproxy:/usr/local/etc/haproxy:ro \
--sysctl net.ipv4.ip_unprivileged_port_start=0 haproxy:2.4
fi
sudo podman run -d -p 8082:8080 -p 8444:8443  \
  --name=quay0 \
  --privileged=true \
  -e DEBUGLOG=true \
  -v $QUAY_CONFIG:/conf/stack:Z \
  -v $QUAY_STORAGE:/datastorage:Z \
  quay.io/projectquay/quay:latest

  sleep 5

  sudo podman run -d -p 8083:8080 -p 8445:8443  \
    --name=quay1 \
    --privileged=true \
    -e DEBUGLOG=true \
    -v $QUAY_CONFIG:/conf/stack:Z \
    -v $QUAY_STORAGE:/datastorage:Z \
    quay.io/projectquay/quay:latest
