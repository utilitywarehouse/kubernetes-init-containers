#!/bin/sh

set -u
set -e

API_ENDPOINT="${API_ENDPOINT:-https://elb.master.k8s.$KUBE_ENV.uw.systems/apis/extensions/v1beta1/namespaces/$NAMESPACE/deployments/$DEPLOYMENT}"

curl -f -X PATCH -k \
	-d "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"$CONTAINER\",\"image\":\"$IMAGE:$TAG\"}]}}}}" \
	-H "Content-Type: application/strategic-merge-patch+json" \
	-H "Authorization: Bearer $K8S_TOKEN" \
	"$API_ENDPOINT"

