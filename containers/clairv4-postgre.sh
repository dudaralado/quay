echo "Deploying Clair Postgre"
sleep 5

mkdir -pv "$HOME/QuayDeploy/postgres-clairv4"

export CLAIRV4_POSTGRE=$HOME/QuayDeploy/postgres-clairv4

sudo setfacl -m u:26:-wx $CLAIRV4_POSTGRE

sudo podman run -d  --name postgresql-clairv4   \
        -e DEBUGLOG=true   \
        -e POSTGRES_USER=clair \
        -e POSTGRES_PASSWORD=pass \
        -e POSTGRES_DB=clair \
        -p 5433:5432 \
        -v $CLAIRV4_POSTGRE:/var/lib/postgresql/data:Z \
        docker.io/library/postgres:latest

sleep 10

sudo podman exec -it postgresql-clairv4 /bin/bash -c 'echo "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"" | psql -d clair -U clair'

sudo podman exec -it postgresql-clairv4 /bin/bash -c 'echo "CREATE database clair_enterprise" | psql -U clair'

sleep 5

sudo podman exec -it postgresql-clairv4 /bin/bash -c 'echo "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"" | psql -d clair_enterprise -U clair'
