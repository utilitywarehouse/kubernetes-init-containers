# Replicated Mongo DB bootstraping script

This is intended to be used in statefulset's `initContainer` to bootstrap a new replicated & authenticated Mongo DB.
StatefulSet must have `podManagementPolicy: Parallel` as the 0th pod will wait for all others to startup

It creates 4 users: metrics exporter, mongolizer (backups), admin (root) and app user.

App user gets rights to APP_DB and should be used in your application.


`REPLICATION_NODES` are in format `hostname:port,hostname:port`
this variable needs to have only secondary nodes, ie starting from 1 (ignoring the 0th, which will be the primary node)

`hostname` - needs to be resolvable by DNS.

## Full examples

- https://github.com/utilitywarehouse/kubernetes-manifests/blob/master/dev/energy/gas-smbtos3-mongodb.yaml
- https://github.com/utilitywarehouse/kubernetes-manifests/blob/master/dev/telecom/bulk-line-test-mongo.yaml

## Example initContainer
```
initContainers:
- name: init-replicated-mongo
  image: registry.uw.systems/utilitywarehouse/uw-mongo-repl-bootstrap:latest
  imagePullPolicy: Always
  volumeMounts:
  - name: test-replicated-mongo
    mountPath: /data/db
  env:
  - name: ADMIN_USER
    valueFrom:
      secretKeyRef:
        name: test-replicated-mongo-secrets
        key: admin.user
  - name: ADMIN_PASSWORD
    valueFrom:
      secretKeyRef:
        name: test-replicated-mongo-secrets
        key: admin.pass
  - name: EXPORTER_USER
    valueFrom:
      secretKeyRef:
        name: test-replicated-mongo-secrets
        key: exporter.user
  - name: EXPORTER_PASSWORD
    valueFrom:
      secretKeyRef:
        name: test-replicated-mongo-secrets
        key: exporter.pass
  - name: MONGOLIZER_USER
    valueFrom:
      secretKeyRef:
        name: test-replicated-mongo-secrets
        key: mongolizer.user
  - name: MONGOLIZER_PASSWORD
    valueFrom:
      secretKeyRef:
        name: test-replicated-mongo-secrets
        key: mongolizer.pass
  - name: APP_USER
    valueFrom:
      secretKeyRef:
        name: test-replicated-mongo-secrets
        key: app.user
  - name: APP_PASSWORD
    valueFrom:
      secretKeyRef:
        name: test-replicated-mongo-secrets
        key: app.pass
  - name: APP_DB
    value: "app-db"
  - name: REPL_SET
    value: "test-replicated-mongo"
  - name: REPLICATION_NODES
    value: "test-replicated-mongo-1.test-replicated-mongo.telecom.svc.cluster.local:27017,test-replicated-mongo-2.test-replicated-mongo.telecom.svc.cluster.local:27017"

```
