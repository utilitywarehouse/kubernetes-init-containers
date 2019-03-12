from mongo:4.0

env ADMIN_USERNAME=${ADMIN_USERNAME:-admin}
env ADMIN_PASSWORD=${ADMIN_PASSWORD}
env EXPORTER_USERNAME=${EXPORTER_USERNAME:-exporter}
env EXPORTER_PASSWORD=${EXPORTER_PASSWORD}
env MONGOLIZER_USERNAME=${MONGOLIZER_USERNAME:-mongolizer}
env MONGOLIZER_PASSWORD=${MONGOLIZER_PASSWORD}
env APP_USERNAME=${APP_USERNAME:-app}
env APP_PASSWORD=${APP_PASSWORD}
env APP_DB=${APP_DB:-app}
env REPLICATION_NODES=${REPLICATION_NODES}
env REPL_SET=${REPL_SET}
env KEY_FILE=${KEY_FILE:-/etc/secrets-volume/internal-auth-mongodb-keyfile}
env DB_ROOT=${DB_ROOT:-/data/db}
env SKIP_BOOTSTRAP=${SKIP_BOOTSTRAP:-false}

copy init.sh /init.sh
user root
run chmod +x /init.sh

entrypoint "/init.sh"
