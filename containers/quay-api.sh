sudo podman run -d -p 8888:8080 \
--name=quay-api \
-e API_URL=https://$FQDN/api/v1/discovery \
docker.io/swaggerapi/swagger-ui
