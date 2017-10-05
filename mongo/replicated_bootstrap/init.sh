#!/bin/bash

[[ `hostname` =~ -([0-9]+)$ ]] || exit 1
ordinal=${BASH_REMATCH[1]}

# Execute user creation and replication setup on the first node only
if [[ $ordinal -ne 0 ]]; then
    exit 0
fi

gosu root mongod --transitionToAuth --clusterAuthMode keyFile --keyFile ${KEY_FILE} --replSet ${REPL_SET} --fork --logpath ${DB_ROOT}/init-admin.log
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
mongo --eval "
rs.initiate( {
   _id : \"${REPL_SET}\",
   members: [ { _id : 0, host : \"${name}\" } ]
})"

# wait for mongodb to understand that it is master
sleep 10

echo "creating user ${ADMIN_USERNAME}"
mongo --authenticationDatabase ${ADMIN_DB:?} --eval "
db.getSiblingDB(\"admin\").createUser({
  user: \"${ADMIN_USERNAME:?}\",
  pwd: \"${ADMIN_PASSWORD:?}\",
  roles: [{ 
	role: \"root\",
	db: \"admin\"
  }]
});
" 

mongo --authenticationDatabase ${ADMIN_DB:?} --eval "
db.getSiblingDB(\"admin\").createUser({
    user: \"${EXPORTER_USERNAME:?}\",
    pwd: \"${EXPORTER_PASSWORD:?}\",
    roles: [
        { role: \"clusterMonitor\", db: \"admin\" },
        { role: \"read\", db: \"local\" }
    ]
});
"

mongo --authenticationDatabase ${ADMIN_DB:?} --eval "
db.getSiblingDB(\"admin\").createUser({
    user: \"${MONGOLIZER_USERNAME:?}\",
    pwd: \"${MONGOLIZER_PASSWORD:?}\",
    roles: [{ role: \"backup\", db:\"admin\"}]
});"

mongo --eval "
db.getSiblingDB(\"${APP_DB:?}\").createUser({
    user: \"${APP_USERNAME:?}\",
    pwd: \"${APP_PASSWORD:?}\",
    roles: [
       { role: \"readWrite\", db: \"${APP_DB:?}\" }
    ]
});"

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


mongod --shutdown
