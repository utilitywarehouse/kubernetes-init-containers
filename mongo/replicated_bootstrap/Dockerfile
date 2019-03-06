from mongo:4.0

env REPLICATION_NODES=${REPLICATION_NODES}
env REPL_SET=${REPL_SET}
env KEY_FILE=${KEY_FILE:-/etc/secrets-volume/internal-auth-mongodb-keyfile}
env DB_ROOT=${DB_ROOT:-/data/db}

copy init.sh /init.sh
user root
run chmod +x /init.sh
entrypoint "/init.sh"
