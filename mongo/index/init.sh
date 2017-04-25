#!/bin/bash
set -e
mongo ${MONGO_HOST:?}:${MONGO_PORT:?}/${USER_DB} --authenticationDatabase ${ADMIN_DB:?} --password ${PASSWORD:?} --username ${USERNAME:?} --eval "
db.runCommand({
  createIndexes: \"${COLLECTION:?}\",
  indexes: [{
    key: {${INDEX_FIELD:?}: 1},
    unique: ${INDEX_UNIQUE:-false},
    name: \"${INDEX_NAME:?}\",
    partialFilterExpression: {
      ${FILTER_EXPRESSION}
    },
  }]
})"
