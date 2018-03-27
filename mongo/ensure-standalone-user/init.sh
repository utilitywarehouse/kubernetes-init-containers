#!/bin/bash
set -e
mongo ${MONGO_HOST:?}:${MONGO_PORT:?}/${USER_DB} --authenticationDatabase ${ADMIN_DB:?} --password ${ADMIN_PASSWORD:?} --username ${ADMIN_USERNAME:?} --eval "
db.createUser({
  user: \"${USERNAME:?}\",
  pwd: \"${PASSWORD:?}\",
    roles: [{
      role: \"readWrite\",
      db: \"${USER_DB:?}\"
    }]
})
" || /bin/true
