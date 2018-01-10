
DOCKER_REGISTRY=registry.uw.systems
DOCKER_REPOSITORY_NAMESPACE=telecom
DOCKER_ID=telco
DOCKER_REPOSITORY_IMAGE=$(SERVICE)
DOCKER_REPOSITORY=registry.uw.systems/$(DOCKER_REPOSITORY_NAMESPACE)/$(DOCKER_REPOSITORY_IMAGE)

GIT_HASH := $(CIRCLE_SHA1)
ifeq ($(GIT_HASH),)
  GIT_HASH := $(shell git rev-parse HEAD)
endif

ci-docker-auth:
	@echo "Logging in to $(DOCKER_REGISTRY) as $(DOCKER_ID)"
	@docker login -u $(DOCKER_ID) -p $(DOCKER_PASSWORD) $(DOCKER_REGISTRY)

all: ci-docker-auth
	$(MAKE) -C mongo/config_bootstrap ci-docker-build
	$(MAKE) -C mongo/replicated_auth_boostrap ci-docker-build
	$(MAKE) -C mongo/shard_bootstrap ci-docker-build
	$(MAKE) -C mongo/replicated_bootstrap ci-docker-build
	$(MAKE) -C mongo/ensure-cluster-user ci-docker-build

