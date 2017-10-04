from mongo:3.4

env ADMIN_USERNAME=${ADMIN_USERNAME:-admin}
env ADMIN_PASSWORD=${ADMIN_PASSWORD:-testpassword}
env EXPORTER_USERNAME=${EXPORTER_USERNAME:-mongodb_exporter}
env EXPORTER_PASSWORD=${EXPORTER_PASSWORD:-testpassword}
env MONGOLIZER_USERNAME=${MONGOLIZER_USERNAME:-mongolizer}
env MONGOLIZER_PASSWORD=${MONGOLIZER_PASSWORD:-testpassword}
env SERVICE_USERNAME=${SERVICE_USERNAME:-service}
env SERVICE_PASSWORD=${SERVICE_PASSWORD:-servicepassword}
env SERVICE_DB=${SERVICE_DB:-servicedb}
env REPLICATION_NODES=${REPLICATION_NODES:-nodes}
env REPL_SET=${REPL_SET:-replSet}
env KEY_FILE=${KEY_FILE:-/etc/secrets-volume/internal-auth-mongodb-keyfile}
env DB_ROOT=${DB_ROOT:-/data/db}

copy init.sh /init.sh
user root
run chmod +x /init.sh
entrypoint "/init.sh"
