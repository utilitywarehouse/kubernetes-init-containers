#!/bin/bash

[ -z "$ADMIN_PASSWORD" ] && echo "Error not set ADMIN_PASSWORD" && exit 1
[ -z "$EXPORTER_PASSWORD" ] && echo "Error not set EXPORTER_PASSWORD" && exit 1
[ -z "$MONGOLIZER_PASSWORD" ] && echo "Error not set MONGOLIZER_PASSWORD" && exit 1
[ -z "$APP_PASSWORD" ] && echo "Error not set APP_PASSWORD" && exit 1

if [ -f ${DB_ROOT}/mongod.lock ]; then
    exit 0
fi

gosu root chown -R root: ${DB_ROOT}

gosu root mongod  --fork --logpath ${DB_ROOT}/init-admin.log
if [ $? -ne 0 ]; then
    cat ${DB_ROOT}/init-admin.log
    exit 1
fi

set -e
sleep 30

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
db.getSiblingDB(\"${APP_DB:?}\").createUser({
    user: \"${APP_USERNAME:?}\",
    pwd: \"${APP_PASSWORD:?}\",
    roles: [
       { role: \"readWrite\", db: \"${APP_DB:?}\" }
    ]
});"

mongo --quiet --eval "
db.getSiblingDB(\"admin\").createUser({
    user: \"${MONGOLIZER_USERNAME:?}\",
    pwd: \"${MONGOLIZER_PASSWORD:?}\",
    roles: [\"backup\"]
});"

mongod --shutdown
