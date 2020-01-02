#!/bin/bash

[ -z "$DB_ROOT" ] && echo "Error not set DB_ROOT" && exit 1
[ -z "$DB_NAME" ] && echo "Error not set DB_NAME" && exit 1
[ -z "$ADMIN_USERNAME" ] && echo "Error not set ADMIN_USERNAME" && exit 1
[ -z "$ADMIN_PASSWORD" ] && echo "Error not set ADMIN_PASSWORD" && exit 1
[ -z "$APP_USERNAME" ] && echo "Error not set APP_USERNAME" && exit 1
[ -z "$APP_PASSWORD" ] && echo "Error not set APP_PASSWORD" && exit 1
[ -z "$EXPORTER_USERNAME" ] && echo "Error not set EXPORTER_USERNAME" && exit 1
[ -z "$EXPORTER_PASSWORD" ] && echo "Error not set EXPORTER_PASSWORD" && exit 1

set -x
echo "CREATE DATABASE ${DB_NAME};

CREATE USER ${APP_USERNAME} WITH PASSWORD '${APP_PASSWORD}';
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${APP_USERNAME};

CREATE USER ${EXPORTER_USERNAME} WITH PASSWORD '${EXPORTER_PASSWORD}';
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${EXPORTER_USERNAME};" >> /docker-entrypoint-initdb.d/init.sql

echo ${ADMIN_PASSWORD} >> /tmp/pwd
su postgres -c "/usr/local/bin/initdb --username="${ADMIN_USERNAME}" --pwfile=/tmp/pwd -D ${DB_ROOT}"

echo "host all all 0.0.0.0/0 password" >> /var/lib/postgresql/data/pg_hba.conf
echo "host all all ::0/0 password" >> /var/lib/postgresql/data/pg_hba.conf
