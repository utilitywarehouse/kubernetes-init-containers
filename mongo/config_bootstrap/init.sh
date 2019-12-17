#!/bin/bash

[ -z "$REPLICATION_NODES" ] && echo "Error not set REPLICATION_NODES" && exit 1
[ -z "$REPL_SET" ] && echo "Error not set REPL_SET" && exit 1
[ -z "$KEY_FILE" ] && echo "Error not set KEY_FILE" && exit 1

[[ `hostname` =~ -([0-9]+)$ ]] || exit 1
ordinal=${BASH_REMATCH[1]}

# Only execute on the 0th node
if [[ $ordinal -ne 0 ]]; then
    exit 0
fi

# https://docs.mongodb.com/manual/tutorial/deploy-sharded-cluster-with-keyfile-access-control/
gosu root mongod --configsvr --keyFile ${KEY_FILE} --replSet ${REPL_SET} --fork --logpath ${DB_ROOT}/init-admin.log --port 27017 --dbpath ${DB_ROOT}
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
   members: [ { _id : 0, host : \"${name}\" } ]
})"

# Wait for MongoDB to become PRIMARY
sleep 10

echo "adding replication nodes"
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

# TODO(kaperys) Can I add users here (directly to the config server)?

mongod --shutdown
