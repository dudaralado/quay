echo "Deploying Config"
sleep 5
sudo podman run --rm -it  -p 8099:8080  \
  --name=config \
  -e DEBUGLOG=true \
  quay.io/projectquay/quay:latest  config test123
