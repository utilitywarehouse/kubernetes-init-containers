#!/bin/bash

[ -z "$REPLICATION_NODES" ] && echo "Error not set REPLICATION_NODES" && exit 1
[ -z "$REPL_SET" ] && echo "Error not set REPL_SET" && exit 1
[ -z "$ADMIN_PASSWORD" ] && echo "Error not set ADMIN_PASSWORD" && exit 1
[ -z "$EXPORTER_PASSWORD" ] && echo "Error not set EXPORTER_PASSWORD" && exit 1
[ -z "$MONGOLIZER_PASSWORD" ] && echo "Error not set MONGOLIZER_PASSWORD" && exit 1

[[ `hostname` =~ -([0-9]+)$ ]] || exit 1
ordinal=${BASH_REMATCH[1]}

# Execute user creation and replication setup on the first node only
if [[ $ordinal -ne 0 ]]; then
    exit 0
fi

gosu root mongod --shardsvr --transitionToAuth --keyFile ${KEY_FILE} --replSet ${REPL_SET} --fork --logpath ${DB_ROOT}/init-admin.log --port 27017 --dbpath ${DB_ROOT}
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
echo "${REPL_SET}"
echo "${REPLICATION_NODES}"
mongo --quiet --eval "
rs.initiate( {
   _id : \"${REPL_SET}\",
   members: [ { _id : 0, host : \"${name}\" } ]
})"

# wait for mongodb to understand that it is master
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
});
" 

mongo --quiet --eval "
db.getSiblingDB(\"admin\").createUser({
    user: \"${EXPORTER_USERNAME:?}\",
    pwd: \"${EXPORTER_PASSWORD:?}\",
    roles: [
        { role: \"clusterMonitor\", db: \"admin\" },
        { role: \"read\", db: \"local\" }
    ]
});
"

mongo --quiet --eval "
db.getSiblingDB(\"admin\").createUser({
    user: \"${MONGOLIZER_USERNAME:?}\",
    pwd: \"${MONGOLIZER_PASSWORD:?}\",
    roles: [{ role: \"backup\", db:\"admin\"}]
});"


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
mongo --quiet --eval "$script"

mongod --shutdown --dbpath ${DB_ROOT} 