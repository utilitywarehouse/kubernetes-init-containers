# Replicated Mongo DB bootstraping script

This is intended to be used in statefulset's `initContainer` to bootstrap a new replicated Mongo DB.

It creates 4 users: metrics exporter, Mongolizer (backups), admin (root) and service user.

`REPLICATION_NODES` are in format `hostname:port,hostname:port`
this variable needs to have only secondary nodes, ie starting from 1 (ignoring the 0th, which will be the primary node)

`hostname` - needs to be resolvable by DNS.

Example initContainer:
```

```
