echo "Deploying Quay Postgre"
sleep 5
mkdir -pv "$HOME/QuayDeploy/postgres-quay"

export QUAY_POSTGRE=$HOME/QuayDeploy/postgres-quay

sudo podman run -d --name postgresql-quay  \
        -e DEBUGLOG=true   \
        -e POSTGRES_USER=quay \
        -e POSTGRES_PASSWORD=pass \
        -e POSTGRES_DB=quay \
        -p 5432:5432 \
        -v $QUAY_POSTGRE:/var/lib/postgresql/data:Z \
        docker.io/library/postgres:latest

sleep 10

echo "Creating extensions"

sudo podman exec -it postgresql-quay /bin/bash -c 'echo "CREATE EXTENSION IF NOT EXISTS pg_trgm" | psql -d quay -U quay'

sudo podman exec -it postgresql-quay /bin/bash -c 'echo "CREATE database quay_enterprise" | psql -U quay'
sleep 5
sudo podman exec -it postgresql-quay /bin/bash -c 'echo "CREATE EXTENSION IF NOT EXISTS pg_trgm" | psql -d quay_enterprise -U quay'
