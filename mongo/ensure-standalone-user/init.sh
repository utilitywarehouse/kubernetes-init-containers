#!/bin/bash
set -e
mongo ${MONGO_HOST:?}:${MONGO_PORT:=27017}/${USER_DB} --authenticationDatabase ${ADMIN_DB:?} --password ${ADMIN_PASSWORD:?} --username ${ADMIN_USERNAME:?} --eval "
db.createUser({
  user: \"${USERNAME:?}\",
  pwd: \"${PASSWORD:?}\",
    roles: [{
      role: \"${ROLE:?}\",
      db: \"${USER_DB:?}\"
    }]
})
" || /bin/true
