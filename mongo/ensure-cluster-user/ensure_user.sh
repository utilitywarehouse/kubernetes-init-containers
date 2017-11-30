#!/bin/bash

nodes=$(echo $MONGO_NODES | tr "," "\n")
masterMarker='"ismaster" : true'

for node in $nodes
do
    checkMaster="mongo $node --username ${ADMIN_USERNAME:?} --password ${ADMIN_PASSWORD:?} --authenticationDatabase ${ADMIN_DB:?} --quiet --eval 'rs.isMaster()'"
    isMaster=$(eval "$checkMaster")

    if [[ $isMaster = *$masterMarker* ]]; then
        checkUserExists="mongo $node --username ${ADMIN_USERNAME:?} --password ${ADMIN_PASSWORD:?} --authenticationDatabase ${ADMIN_DB:?} --quiet --eval 'db.getSiblingDB(\"${MONGO_DB:?}\").getUser(\"${MONGO_USERNAME:?}\");'"
        userExists=$(eval "$checkUserExists")

        if [[ $(eval "echo -n \"$userExists\"") = "null" ]]; then
            echo "creating user"
            createUser="mongo $node --username ${ADMIN_USERNAME:?} --password ${ADMIN_PASSWORD:?} --authenticationDatabase ${ADMIN_DB:?} --quiet --eval 'db.getSiblingDB(\"${MONGO_DB:?}\").createUser({user: \"${MONGO_USERNAME:?}\", pwd: \"${MONGO_PASSWORD:?}\", roles: [{ role: \"${ROLE:?}\", db: \"${MONGO_DB:?}\"}]})'"
            result=$(eval "$createUser")
            echo $result
        fi
    fi
done