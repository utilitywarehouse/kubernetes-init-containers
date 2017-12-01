# kubernetes-init-containers

a collection of containers that are created for being run as kubernetes
init-containers to perform setup before the main pod containers are started.


## Mongo initContainers

### Replicated mongo

- uw-mongo-repl-bootstrap docker image, bootstraps replicated mongo with authentication enabled [More info](./mongo/replicated_auth_boostrap/README.md)

### Sharded mongo 
- uw-mongo-config docker image, bootstraps config server [More info](./mongo/config_bootstrap/README.md)
- uw-mongo-shard docker image, bootstraps shard server [More info](./mongo/shard_bootstrap/README.md)

## Build

Circle CI builds and pushes images into docker registry
