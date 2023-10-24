export MINIO_DIR=$HOME/QuayDeploy
sudo rm -rfv $MINIO_DIR/minio
sudo mkdir $MINIO_DIR/minio

export QUAY_CONFIG=$HOME/QuayDeploy/quay/config
export QUAY_STORAGE=$HOME/QuayDeploy/quay/storage

sed -i '/^DISTRIBUTED_STORAGE_CONFIG/,+3d' $QUAY_CONFIG/config.yaml

sed -i '/^DEFAULT_TAG_EXPIRATION/a DISTRIBUTED_STORAGE_CONFIG:\n    default:\
\n        - RadosGWStorage\
\n        - access_key: minioadmin\
\n          bucket_name: quay-standalone\
\n          hostname: HOSTNAME_FQDN\
\n          is_secure: false\
\n          port: "9000"\
\n          secret_key: minioadmin\
\n          storage_path: /datastorage/registry' $QUAY_CONFIG/config.yaml

sed -i '/^$/d' $QUAY_CONFIG/config.yaml

#######################################################
## Creating minIO ObejectStorage in case want to use ##
#######################################################
#echo "Deploying MinIO"
sleep 5
sudo podman pull docker.io/minio/minio:latest
sudo podman run -d --name minio \
     -e DEBUGLOG=true   \
     -p 9000:9000 -p 9001:9001  \
     -v $MINIO_DIR/minio:/data:Z minio/minio server --console-address :9001 /data


curl https://dl.min.io/client/mc/release/linux-amd64/mc \
     --create-dirs \
     -o $HOME/minio-binaries/mc

chmod +x $HOME/minio-binaries/mc
export PATH=$PATH:$HOME/minio-binaries/

mc alias set myminio http://$FQDN:9000 minioadmin minioadmin
mc mb myminio/quay-standalone
mc mb myminio/quay-enterprise


#sudo sed -i '/^SECURITY_SCANNER_INDEXING_INTERVAL/a SECURITY_SCANNER_V4_PSK: NmEwOGU5NDBqODU5' $QUAY_CONFIG/config.yaml
