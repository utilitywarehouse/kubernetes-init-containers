#!/bin/bash

[ -z "$REPLICATION_NODES" ] && echo "Error not set REPLICATION_NODES" && exit 1
[ -z "$SHARD_NODES" ] && echo "Error not set SHARD_NODES" && exit 1
[ -z "$REPL_SET" ] && echo "Error not set REPL_SET" && exit 1
[ -z "$ADMIN_PASSWORD" ] && echo "Error not set ADMIN_PASSWORD" && exit 1
[ -z "$EXPORTER_PASSWORD" ] && echo "Error not set EXPORTER_PASSWORD" && exit 1
[ -z "$MONGOLIZER_PASSWORD" ] && echo "Error not set MONGOLIZER_PASSWORD" && exit 1
[ -z "$APP_PASSWORD" ] && echo "Error not set APP_PASSWORD" && exit 1

[[ `hostname` =~ -([0-9]+)$ ]] || exit 1
ordinal=${BASH_REMATCH[1]}

# Execute user creation and replication setup on the first node only
if [[ $ordinal -ne 0 ]]; then
    exit 0
fi

gosu root mongod --configsvr --transitionToAuth --keyFile ${KEY_FILE} --replSet ${REPL_SET} --fork --logpath ${DB_ROOT}/init-admin.log --port 27017 --dbpath ${DB_ROOT}
if [ $? -ne 0 ]; then
    cat ${DB_ROOT}/init-admin.log
    exit 1
fi

set -e
sleep 30

# check if replication is initialized 
res="$(mongo --quiet --eval='printjson(rs.status())')"
if [[ $res != *"NotYetInitialized"* ]]; then
    exit 0
fi

name=$(hostname -f)

echo "starting bootstrap"
mongo --quiet --eval "
rs.initiate( {
   _id : \"${REPL_SET}\",
   members: [ { _id : 0, host : \"${name}\" } ]
})"

# wait for mongodb to understand that it is master
sleep 10

# Seriously Mongo doesn't allow you to add shards to config server directly
# you have to spin up a mongos router to do that
echo "Starting mongos instance"

set +e
gosu root mongos --transitionToAuth --keyFile ${KEY_FILE} --fork --logpath ${DB_ROOT}/init-mongos.log --port 27018 --configdb ${REPL_SET}/localhost:27017
if [ $? -ne 0 ]; then
    cat ${DB_ROOT}/init-mongos.log
    exit 1
fi

set -e
sleep 15

echo "creating user ${ADMIN_USERNAME}"
mongo localhost:27018 --quiet --eval "
db.getSiblingDB(\"admin\").createUser({
  user: \"${ADMIN_USERNAME:?}\",
  pwd: \"${ADMIN_PASSWORD:?}\",
  roles: [{ 
	role: \"root\",
	db: \"admin\"
  }]
});
" 

mongo localhost:27018 --quiet --eval "
db.getSiblingDB(\"admin\").createUser({
    user: \"${EXPORTER_USERNAME:?}\",
    pwd: \"${EXPORTER_PASSWORD:?}\",
    roles: [
        { role: \"clusterMonitor\", db: \"admin\" },
        { role: \"read\", db: \"local\" }
    ]
});
"

mongo localhost:27018 --quiet --eval "
db.getSiblingDB(\"admin\").createUser({
    user: \"${MONGOLIZER_USERNAME:?}\",
    pwd: \"${MONGOLIZER_PASSWORD:?}\",
    roles: [{ role: \"backup\", db:\"admin\"}]
});"

mongo localhost:27018 --quiet --eval "
db.getSiblingDB(\"${APP_DB:?}\").createUser({
    user: \"${APP_USERNAME:?}\",
    pwd: \"${APP_PASSWORD:?}\",
    roles: [
       { role: \"readWrite\", db: \"${APP_DB:?}\" }
    ]
});"

echo "shard config init" 
nodes=$(echo $SHARD_NODES | tr "," "\n")
for node in $nodes
do
    while true
    do
        script="mongo localhost:27018 --quiet --eval 'sh.addShard(\"${node}\")'"
        out=$(eval "$script")
        echo $out
        if [[ $out == *"shardAdded"* ]]; then
            break
        fi
        echo "retrying ${node}"
        sleep 5
    done
done

mongo localhost:27018 --quiet --eval "sh.enableSharding(\"${APP_DB}\")"

echo "rs config init ${name}"
nodes=$(echo $REPLICATION_NODES | tr "," "\n")
counter=1
for node in $nodes
do
    echo "adding replica ${node}, ${counter}"
    while true
    do
        script="mongo --quiet --eval 'rs.add({_id: ${counter}, host:\"${node}\", priority: 0.99})'"
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

mongod --shutdown
