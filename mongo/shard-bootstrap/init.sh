#!/bin/bash

function init_config_replicaset() {
  echo "Configuring configuration server"
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

  if [ -f ${DB_ROOT}/mongod.lock ]; then
      exit 0
  fi

  if [[ ${SKIP_BOOTSTRAP} != *"false"* ]]; then
      exit 0
  fi

  gosu root chown -R root: ${DB_ROOT}

  gosu root mongod --transitionToAuth --clusterAuthMode keyFile --keyFile ${KEY_FILE} --configsvr --replSet ${REPL_SET} --fork --dbpath=${DB_ROOT} --logpath ${DB_ROOT}/init-admin.log
  if [ $? -ne 0 ]; then
      cat ${DB_ROOT}/init-admin.log
      exit 1
  fi

  set -e
  sleep 30

  # check if replication is initialized
  res="$(mongo --quiet --eval='printjson(rs.status())' localhost:27019)"
  if [[ $res != *"NotYetInitialized"* ]]; then
      exit 0
  fi

  name=$(hostname -f)
  if [[ ${MASTER_NODE} ]]; then
      name=${MASTER_NODE}
  fi

  echo "starting bootstrap"
  mongo --quiet --eval "
  rs.initiate( {
     _id : \"${REPL_SET}\",
     configsvr: true,
     members: [ { _id : 0, host : \"${name}:27019\" } ]
  })" localhost:27019

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
  " localhost:27019

  mongo --quiet --eval "
  db.getSiblingDB(\"admin\").createUser({
      user: \"${EXPORTER_USERNAME:?}\",
      pwd: \"${EXPORTER_PASSWORD:?}\",
      roles: [
          { role: \"clusterMonitor\", db: \"admin\" },
          { role: \"read\", db: \"local\" }
      ]
  });
  " localhost:27019

  mongo --quiet --eval "
  db.getSiblingDB(\"admin\").createUser({
      user: \"${MONGOLIZER_USERNAME:?}\",
      pwd: \"${MONGOLIZER_PASSWORD:?}\",
      roles: [\"backup\"]
  });" localhost:27019


  echo "rs config init ${name}"
  nodes=$(echo $REPLICATION_NODES | tr "," "\n")
  counter=1
  for node in $nodes
  do
      echo "adding replica ${node}, ${counter}"
      while true
      do
          script="mongo --quiet --eval 'rs.add({_id: ${counter}, host:\"${node}\", priority: 0.99})' localhost:27019"
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
  mongo --eval "$script" localhost:27019


  if [[ "$TAGS" ]]; then
      script="cfg = rs.conf();$NEWLINE"
      for i in `seq 0 $((counter-1))`; do
          IFS=';' read -ra TAGS_ARR <<< "$TAGS"
          for t in "${TAGS_ARR[@]}"; do
              script="$script cfg.members[$i].tags[\"${t%%=*}\"]=\"${t#*=}\";$NEWLINE"
          done
      done
      script="$script rs.reconfig(cfg);$NEWLINE"
      mongo --eval "$script" localhost:27019
  fi

  sleep 60

  mongod --configsvr --dbpath=${DB_ROOT} --shutdown

  exit 0
}

function init_shard_replicaset() {
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

  if [ -f ${DB_ROOT}/mongod.lock ]; then
      exit 0
  fi

  if [[ ${SKIP_BOOTSTRAP} != *"false"* ]]; then
      exit 0
  fi

  gosu root chown -R root: ${DB_ROOT}

  gosu root mongod --shardsvr --transitionToAuth --clusterAuthMode keyFile --keyFile ${KEY_FILE} --replSet ${REPL_SET} --dbpath=${DB_ROOT} --fork --logpath ${DB_ROOT}/init-admin.log
  if [ $? -ne 0 ]; then
      cat ${DB_ROOT}/init-admin.log
      exit 1
  fi

  set -e
  sleep 30

  # check if replication is initialized
  res="$(mongo --quiet --eval='printjson(rs.status())' localhost:27018)"
  if [[ $res != *"NotYetInitialized"* ]]; then
      exit 0
  fi

  name=$(hostname -f)
  if [[ ${MASTER_NODE} ]]; then
      name=${MASTER_NODE}
  fi

  echo "starting bootstrap"
  mongo --quiet --eval "
  rs.initiate( {
     _id : \"${REPL_SET}\",
     members: [ { _id : 0, host : \"${name}:27018\" } ]
  })"  localhost:27018

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
  " localhost:27018

  mongo --quiet --eval "
  db.getSiblingDB(\"admin\").createUser({
      user: \"${EXPORTER_USERNAME:?}\",
      pwd: \"${EXPORTER_PASSWORD:?}\",
      roles: [
          { role: \"clusterMonitor\", db: \"admin\" },
          { role: \"read\", db: \"local\" }
      ]
  });
  " localhost:27018

  mongo --quiet --eval "
  db.getSiblingDB(\"admin\").createUser({
      user: \"${MONGOLIZER_USERNAME:?}\",
      pwd: \"${MONGOLIZER_PASSWORD:?}\",
      roles: [\"backup\"]
  });" localhost:27018


  echo "rs config init ${name}"
  nodes=$(echo $REPLICATION_NODES | tr "," "\n")
  counter=1
  for node in $nodes
  do
      echo "adding replica ${node}, ${counter}"
      while true
      do
          script="mongo --quiet --eval 'rs.add({_id: ${counter}, host:\"${node}\", priority: 0.99})' localhost:27018"
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
  mongo --eval "$script" localhost:27018


  if [[ "$TAGS" ]]; then
      script="cfg = rs.conf();$NEWLINE"
      for i in `seq 0 $((counter-1))`; do
          IFS=';' read -ra TAGS_ARR <<< "$TAGS"
          for t in "${TAGS_ARR[@]}"; do
              script="$script cfg.members[$i].tags[\"${t%%=*}\"]=\"${t#*=}\";$NEWLINE"
          done
      done
      script="$script rs.reconfig(cfg);$NEWLINE"
      mongo --eval "$script" localhost:27018
  fi

  sleep 60

  mongod --shardsvr --dbpath=${DB_ROOT} --shutdown

  exit 0
}

function init_mongos() {
  [ -z "$SHARD_MEMBERS" ] && echo "Error not set SHARD_MEMBERS" && exit 1
  [ -z "$CONFIG_DB" ] && echo "Error not set CONFIG_DB" && exit 1
  [ -z "$ADMIN_PASSWORD" ] && echo "Error not set ADMIN_PASSWORD" && exit 1
  [ -z "$EXPORTER_PASSWORD" ] && echo "Error not set EXPORTER_PASSWORD" && exit 1
  [ -z "$MONGOLIZER_PASSWORD" ] && echo "Error not set MONGOLIZER_PASSWORD" && exit 1

  if [ -f ${DB_ROOT}/mongod.lock ]; then
      exit 0
  fi

  if [[ ${SKIP_BOOTSTRAP} != *"false"* ]]; then
      exit 0
  fi

  gosu root chown -R root: ${DB_ROOT}

  gosu root mongos --configdb "${CONFIG_DB}" --transitionToAuth --clusterAuthMode keyFile --keyFile ${KEY_FILE} --fork --logpath ${DB_ROOT}/init-admin.log
  if [ $? -ne 0 ]; then
      cat ${DB_ROOT}/init-admin.log
      exit 1
  fi

  set -e
  sleep 30


  echo "adding shards"
  shards=$(echo $SHARD_MEMBERS | tr "|" "\n")
  for shard in $shards
  do
    echo "adding shard ${shard}"
    mongo --quiet --eval="
    sh.addShard(\"${shard}\")
    "
  done

  echo "sharding database ${APP_DB}"
  mongo --quiet --eval="
  sh.enableSharding(\"${APP_DB}\")
  "

  sleep 30

  mongo admin --quiet --eval="db.shutdownServer()" || true
  exit 0
}

case $1 in
  "config-server")
  init_config_replicaset
  ;;
  "shard-server")
  init_shard_replicaset
  ;;
  "mongos")
  init_mongos
  ;;
  *)
    echo "missing argument"
esac
