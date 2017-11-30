
DOCKER_REGISTRY=registry.uw.systems
DOCKER_REPOSITORY_NAMESPACE=telecom
DOCKER_ID=telco
DOCKER_REPOSITORY_IMAGE=$(SERVICE)
DOCKER_REPOSITORY=registry.uw.systems/$(DOCKER_REPOSITORY_NAMESPACE)/$(DOCKER_REPOSITORY_IMAGE)

GIT_HASH := $(CIRCLE_SHA1)
ifeq ($(GIT_HASH),)
  GIT_HASH := $(shell git rev-parse HEAD)
endif

all: build

ci-docker-auth:
	@echo "Logging in to $(DOCKER_REGISTRY) as $(DOCKER_ID)"
	@docker login -u $(DOCKER_ID) -p $(DOCKER_PASSWORD) $(DOCKER_REGISTRY)

build:
	docker build -t $(DOCKER_REPOSITORY):$(GIT_HASH) .
	docker tag $(DOCKER_REPOSITORY):$(GIT_HASH) $(DOCKER_REPOSITORY):latest

ci-docker-build: ci-docker-auth
	docker build -t $(DOCKER_REPOSITORY):$(CIRCLE_SHA1) .
	docker tag $(DOCKER_REPOSITORY):$(CIRCLE_SHA1) $(DOCKER_REPOSITORY):latest
	docker push $(DOCKER_REPOSITORY)

