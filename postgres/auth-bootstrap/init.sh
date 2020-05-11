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

# only continue if the database isn't already initialised
if [ -s "${DB_ROOT}/PG_VERSION" ]; then
    exit 0
fi

cat <<EOF >> /tmp/pwd
${ADMIN_PASSWORD}
EOF

mkdir -p ${DB_ROOT}
chown postgres:postgres -R ${DB_ROOT}
su postgres -c "/usr/local/bin/initdb --username="${ADMIN_USERNAME}" --pwfile=/tmp/pwd -D ${DB_ROOT}"

cat <<EOF >> /init.sql
CREATE DATABASE ${DB_NAME};

CREATE USER ${APP_USERNAME} WITH PASSWORD '${APP_PASSWORD}';
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${APP_USERNAME};
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${APP_USERNAME};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO ${APP_USERNAME};

CREATE USER ${EXPORTER_USERNAME} WITH PASSWORD '${EXPORTER_PASSWORD}';
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${EXPORTER_USERNAME};
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${EXPORTER_USERNAME};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO ${EXPORTER_USERNAME};
EOF

su postgres -c "postgres -D ${DB_ROOT}" &
sleep 5

psql -v ON_ERROR_STOP=1 --username "${ADMIN_USERNAME}" --no-password -f /init.sql
