#!/bin/bash
set -e

[[ `hostname` =~ -([0-9]+)$ ]] || exit 1
ordinal=${BASH_REMATCH[1]}

# Execute user creation and replication setup on the first node only
if [[ $ordinal -ne 0 ]]; then
    exit 0
fi

chown -R mongodb ${DB_ROOT:?}
gosu mongodb mongod --replSet ${REPL_SET} -fork --logpath ${DB_ROOT}/init-admin.log
# new primary needs to wait while secondaries become active
# This will be executed on creation only
sleep 45

# check if replication is initialized 
res="$(mongo --quiet --eval='printjson(rs.status())')"
if [[ $res != *"NotYetInitialized"* ]]; then
    exit 0
fi

name=$(hostname -f)

echo "starting bootstrap"
mongo --eval "
rs.initiate( {
   _id : \"${REPL_SET}\",
   members: [ { _id : 0, host : \"${name}\" } ]
})"

echo "rs config init ${name}"
nodes=$(echo $REPLICATION_NODES | tr "," "\n")
for node in $nodes
do
    echo "adding replica ${node}"
    mongo --eval "rs.add({host:\"${node}\", priority: 0.99})"
done

echo "creating user ${ADMIN_USERNAME}"
mongo --eval "
db.createUser({
  user: \"${ADMIN_USERNAME:?}\",
  pwd: \"${ADMIN_PASSWORD:?}\",
  roles: [{ 
	role: \"root\",
	db: \"admin\"
  }]
});
" 

mongo --eval "
db.getSiblingDB(\"admin\").createUser({
    user: \"${EXPORTER_USERNAME:?}\",
    pwd: \"${EXPORTER_PASSWORD:?}\",
    roles: [
        { role: \"clusterMonitor\", db: \"admin\" },
        { role: \"read\", db: \"local\" }
    ]
});
"

mongo --eval "
db.createUser({
    user: \"${MONGOLIZER_USERNAME:?}\",
    pwd: \"${MONGOLIZER_PASSWORD:?}\",
    roles: [{ role: \"backup\", db:\"admin\"}]
});"

mongo --eval "
db.createUser({
    user: \"${SERVICE_USERNAME:?}\",
    pwd: \"${SERVICE_PASSWORD:?}\",
    roles: [
       { role: \"readWrite\", db: \"${SERVICE_DB:?}\" }
    ]
});"

mongod --shutdown
