#!/bin/bash

set -eu

. common.sh

load-images() {
    local kind_name=$1; shift
    local container_images=("$@")

    for image in "${container_images[@]}"; do
        ${KIND_PATH} load docker-image --name $kind_name "${image}"
    done
}

# Load builded images
container_images=("spiffe-helper:latest-local" "client-service:latest-local" "api-service:latest-local")
load-images ${CLUSTER_NAME} "${container_images[@]}"

# Deploy SPIRE Server
log-info "Deploying SPIRE Server"
${KUBECTL_PATH} create namespace spire
${KUBECTL_PATH} apply -k ./k8s/spire/server

log-info "Waiting for SPIRE Server"
${KUBECTL_PATH} wait --for=condition=Ready --timeout=300s pod/spire-server-0 -n spire

log-info "Creating entries"
cat entries.json | ${KUBECTL_PATH} exec -n spire spire-server-0 -c spire-server -i -- /opt/spire/bin/spire-server entry create -data -

log-info "Deploying SPIRE Agent"
${KUBECTL_PATH} apply -k ./k8s/spire/agent

log-info "Waiting for SPIRE Agent"
agentName=$(${KUBECTL_PATH} get pod -n spire -l app=spire-agent -o jsonpath="{.items[0].metadata.name}")
${KUBECTL_PATH} wait --for=condition=Ready --timeout=300s pod/${agentName} -n spire

log-info "Deploy pods"
${KUBECTL_PATH} apply -k ./k8s/demo

