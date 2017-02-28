#!/bin/bash
set -e
chown -R mongodb ${DB_ROOT:?}
gosu mongodb mongod --fork --logpath ${DB_ROOT}/init-admin.log
sleep 5
mongo ${ADMIN_DB:?} --eval "
db.createUser({
  user: \"${USERNAME:?}\",
    pwd: \"${PASSWORD:?}\",
      roles: [{ 
	role: \"userAdminAnyDatabase\",
	db: \"admin\"
      }]
})" || /bin/true
mongod --shutdown
