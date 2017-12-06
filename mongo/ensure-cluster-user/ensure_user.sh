#!/bin/bash

mongoURL="mongodb://${SERVICE_NAME}/${MONGO_DB}?replicaSet=${REPLICA_SET}"

checkUserExists="mongo $mongoURL --username ${ADMIN_USERNAME:?} --password ${ADMIN_PASSWORD:?} --authenticationDatabase ${ADMIN_DB:?} --quiet --eval 'db.getSiblingDB(\"${MONGO_DB:?}\").getUser(\"${MONGO_USERNAME:?}\");'"
userExists=$(eval "$checkUserExists")

if [[ $(eval "echo -n \"$userExists\"") = *"null"* ]]; then
    createUser="mongo $mongoURL --username ${ADMIN_USERNAME:?} --password ${ADMIN_PASSWORD:?} --authenticationDatabase ${ADMIN_DB:?} --quiet --eval 'db.getSiblingDB(\"${MONGO_DB:?}\").createUser({user: \"${MONGO_USERNAME:?}\", pwd: \"${MONGO_PASSWORD:?}\", roles: [{ role: \"${ROLE:?}\", db: \"${MONGO_DB:?}\"}]})'"
    result=$(eval "$createUser")
    echo $result
fi