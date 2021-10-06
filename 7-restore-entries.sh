#!/bin/bash

set -eu

. common.sh

${KUBECTL_PATH} exec -n spire spire-server-0 -c spire-server -- /opt/spire/bin/spire-server entry show \
  -spiffeID spiffe://example.org/api-proxy > /tmp/entryFound

ENTRYID=$( grep 'Entry ID         :' /tmp/entryFound | awk '{print $4}')
echo $ENTRYID

log-info "Restoring api-proxy entry"
${KUBECTL_PATH} exec -n spire spire-server-0 -c spire-server -- /opt/spire/bin/spire-server entry update \
     -entryID $ENTRYID \
     -parentID spiffe://example.org/spire-agent-node \
     -spiffeID spiffe://example.org/api-proxy \
     -selector k8s:container-name:api-proxy \
     -selector k8s:ns:api-ns \
     -ttl 60

${KUBECTL_PATH} exec -n spire spire-server-0 -c spire-server -- /opt/spire/bin/spire-server entry show \
  -spiffeID spiffe://example.org/api > /tmp/entryFound

ENTRYID=$( grep 'Entry ID         :' /tmp/entryFound | awk '{print $4}')
echo $ENTRYID

log-info "Restoring api-sidecar entry to a valid DNS"
${KUBECTL_PATH} exec -n spire spire-server-0 -c spire-server -- /opt/spire/bin/spire-server entry update \
    -entryID $ENTRYID \
    -parentID spiffe://example.org/spire-agent-node \
    -spiffeID spiffe://example.org/api \
    -selector k8s:container-name:api \
    -selector k8s:ns:api-ns \
    -dns symuser \
    -ttl 60



