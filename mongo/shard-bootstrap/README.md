# Mongo shard bootstrap script

This is intended to be used in statefulset's `initContainer` to bootstrap a new Mongo DB shard.
StatefulSet must have `podManagementPolicy: Parallel` as the 0th pod will wait for all others to startup


## Build
```
docker build -t registry.uw.systems/utilitywarehouse/uw-mongo-shard:latest .

docker push  registry.uw.systems/utilitywarehouse/uw-mongo-shard:latest
```


