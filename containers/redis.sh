########################################################
## Creating pods to be used on Quay Simple Enviroment ##
########################################################
echo "Deploying Redis"
sleep 5
sudo podman run -d  --name redis \
        -e DEBUGLOG=true   \
        -p 6379:6379 \
        docker.io/library/redis:latest \
        --requirepass strongpassword
