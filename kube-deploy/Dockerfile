from alpine:3.6

run apk --no-cache add curl ca-certificates

env KUBE_ENV="${kube_env:-dev}"
env NAMESPACE="telecom"
copy run.sh /
entrypoint ["/bin/sh", "-c"]
cmd ["/run.sh"]


