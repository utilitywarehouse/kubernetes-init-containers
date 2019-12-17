#!/bin/bash

[ -z "$REPLICATION_NODES" ] && echo "Error not set REPLICATION_NODES" && exit 1
[ -z "$REPL_SET" ] && echo "Error not set REPL_SET" && exit 1
[ -z "$KEY_FILE" ] && echo "Error not set KEY_FILE" && exit 1
[ -z "$ADMIN_PASSWORD" ] && echo "Error not set ADMIN_PASSWORD" && exit 1
[ -z "$EXPORTER_PASSWORD" ] && echo "Error not set EXPORTER_PASSWORD" && exit 1

[[ `hostname` =~ -([0-9]+)$ ]] || exit 1
ordinal=${BASH_REMATCH[1]}

# Only execute on the 0th node
if [[ $ordinal -ne 0 ]]; then
    exit 0
fi

# https://docs.mongodb.com/manual/tutorial/deploy-sharded-cluster-with-keyfile-access-control/
gosu root mongod --configsvr --transitionToAuth --keyFile ${KEY_FILE} --replSet ${REPL_SET} --logpath ${DB_ROOT}/init-admin.log --dbpath ${DB_ROOT} -vv &
if [ $? -ne 0 ]; then
    cat ${DB_ROOT}/init-admin.log
    exit 1
fi

set -e
sleep 30

# If the cluster has already been initialised, exit
res="$(mongo --quiet --eval='printjson(rs.status())')"
if [[ $res != *"NotYetInitialized"* ]]; then
    exit 0
fi

name=$(hostname -f)

echo "initialising replicaset with 0th node"
mongo --quiet --eval "
rs.initiate( {
   _id : \"${REPL_SET}\",
   configsvr: true,
   members: [ { _id : 0, host : \"${name}:27019\" } ]
})"

# Wait for MongoDB to become PRIMARY
sleep 10

echo "creating user ${ADMIN_USERNAME}"
mongo --quiet --eval "
db.getSiblingDB(\"admin\").createUser({
  user: \"${ADMIN_USERNAME:?}\",
  pwd: \"${ADMIN_PASSWORD:?}\",
  roles: [{
	role: \"root\",
	db: \"admin\"
  }]
});"

echo "creating user ${EXPORTER_USERNAME}"
mongo --quiet --eval "
db.getSiblingDB(\"admin\").createUser({
    user: \"${EXPORTER_USERNAME:?}\",
    pwd: \"${EXPORTER_PASSWORD:?}\",
    roles: [
        { role: \"clusterMonitor\", db: \"admin\" },
        { role: \"read\", db: \"local\" }
    ]
});"

nodes=$(echo $REPLICATION_NODES | tr "," "\n")
counter=1
for node in $nodes
do
    echo "adding replica ${counter} ${node}"
    while true
    do
        script="mongo --quiet --eval 'rs.add({_id: ${counter}, host:\"${node}:27019\", priority: 0.99})'"
        out=$(eval "$script")
        echo $out
        if [[ $out != *"NodeNotFound"* ]]; then
            break
        fi

        echo "retrying ${node}"
        sleep 5
    done

    counter=$[$counter +1]
done

echo "reconfiguring the replicaset with all replication nodes"
NEWLINE=$'\n'
script="cfg = rs.conf();$NEWLINE"
script="$script cfg.members[0].priority = 1;$NEWLINE"
counter=1
for node in $nodes
do
    member="cfg.members[${counter}].priority = 1;$NEWLINE"
    script="$script$member"
    counter=$[$counter +1]
done 
script="$script rs.reconfig(cfg);$NEWLINE"
mongo --eval "$script"

echo "initialisation complete"
mongod --shutdown
