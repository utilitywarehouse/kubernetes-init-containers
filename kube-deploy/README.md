# kube-deploy

## usage of this image for deployments

	docker run --rm -ti \
		-e DEPLOYMENT=speedcheck \
		-e NAMESPACE=telecom \
		-e K8S_DEV_TOKEN \
		-e CONTAINER=speedcheck \
		-e IMAGE=registry.uw.systems/telecom/speedcheck \
		-e TAG=latest \
		registry.uw.systems/tools/kube-deploy:latest

## variables

- KUBE_ENV # `dev / experimental / prod` kubernetes environment
- DEPLOYMENT #target deployment in k8s
- NAMESPACE #namespace of deployment in k8s
- K8S_DEV_TOKEN #k8s namespace secret
- CONTAINER #target container in deployment
- IMAGE #source image - will probably end up looking like $UW_REGISTRY/$NAMESPACE/$SERVICE
- TAG #tag of image to deploy - most likely $CIRCLE_HASH

you can also override the `API_ENDPOINT` variable, which will then be used to connect to the k8s api
