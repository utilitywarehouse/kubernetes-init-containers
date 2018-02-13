# Replicated Mongo DB bootstraping script

This is intended to be used in statefulset's `initContainer` to bootstrap a new replicated & authenticated Mongo DB.
StatefulSet must have `podManagementPolicy: Parallel` as the 0th pod will wait for all others to startup

It creates 4 users: metrics exporter, mongolizer (backups), admin (root) and app user.

- If `ADMIN_USERNAME` env is not specified, by default creates `admin` user
- If `EXPORTER_USERNAME` env is not specified, by default creates `exporter` user
- If `MONGOLIZER_USERNAME` env is not specified, by default creates `mongolizer` user
- If `APP_USERNAME` env is not specified, by default creates `app` user

App user gets rights to APP_DB and should be used in your application.

`REPLICATION_NODES` are in format `hostname:port,hostname:port`
this variable needs to have only secondary nodes, ie starting from 1 (ignoring the 0th, which will be the primary node)

`hostname` - needs to be resolvable by DNS.

Optionally, members can be tagged alike by setting the `TAGS` env var, e.g. `TAGS="read=enabled;dc=east"`.

## Build 
```

make 

```
## Full examples

- https://github.com/utilitywarehouse/kubernetes-manifests/blob/master/dev/telecom/mso-mssql-bridge-mongo.yaml

## Tips

Check that your `kubectl version` client version is 1.7 or above.

You can generate keyFile using `openssl rand 741 -base64 | base64 -w0`

Mongodb connection string is in form `[mongodb://][user:pass@]host1[:port1][,host2[:port2],...][/database][?options]`

Exporter needs to connect to localhost, it's connection string is `mongob://exporter_username:exporter_password@localhost:27017/admin`

App connection string is in form of:
`mongodb://APP_USERNAME:APP_PASSWORD@K8S_SERVICE_NAME/DB_NAME?replicaSet=REPLICA_SET_NAME`

Consider doing writes with `w:"majority"` writeConcern. More info https://docs.mongodb.com/manual/reference/write-concern/#writeconcern._dq_majority_dq_.

Other useful tips: https://docs.mongodb.com/manual/administration/production-checklist-operations/#replication

## Example initContainer
```
    initContainers:
      - name: init-replicated-mongo
        image: registry.uw.systems/utilitywarehouse/uw-mongo-repl-bootstrap:latest
        imagePullPolicy: Always
        volumeMounts:
        - name: gas-smbtos3-mongo
          mountPath: /data/db
        - name: secrets-volume
          readOnly: true
          mountPath: /etc/secrets-volume
        env:
        - name: ADMIN_PASSWORD
          valueFrom:
            secretKeyRef:
              name: gas-smbtos3-secrets
              key: admin.pass
        - name: EXPORTER_PASSWORD
          valueFrom:
            secretKeyRef:
              name: gas-smbtos3-secrets
              key: exporter.pass
        - name: MONGOLIZER_PASSWORD
          valueFrom:
            secretKeyRef:
              name: gas-smbtos3-secrets
              key: mongolizer.pass
        - name: APP_USERNAME
          valueFrom:
            secretKeyRef:
              name: gas-smbtos3-secrets
              key: app.user
        - name: APP_PASSWORD
          valueFrom:
            secretKeyRef:
              name: gas-smbtos3-secrets
              key: app.pass
        - name: APP_DB
          value: "gas-smbtos3"
        - name: REPL_SET
          value: "gas-smbtos3-mongo"
        - name: REPLICATION_NODES
          value: "gas-smbtos3-mongo-1.gas-smbtos3-mongo.energy.svc.cluster.local,gas-smbtos3-mongo-2.gas-smbtos3-mongo.energy.svc.cluster.local"

```
