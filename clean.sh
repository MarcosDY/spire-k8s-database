#!/bin/bash

. common.sh

${KUBECTL_PATH} delete -k k8s/spire/server
${KUBECTL_PATH} delete -k k8s/spire/agent
${KUBECTL_PATH} delete ns spire
${KUBECTL_PATH} delete -k k8s/demo

docker image rm spiffe-helper:latest-local
docker image rm client-service:latest-local
docker image rm api-service:latest-local
