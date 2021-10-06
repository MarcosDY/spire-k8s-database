#!/bin/bash

set -eu

. common.sh

${KUBECTL_PATH} exec -n spire spire-server-0 -c spire-server -- /opt/spire/bin/spire-server entry show \
  -spiffeID spiffe://example.org/api > /tmp/entryFound

ENTRYID=$( grep 'Entry ID         :' /tmp/entryFound | awk '{print $4}')

log-info "Changing DNS in Spire Entry"
${KUBECTL_PATH} exec -n spire spire-server-0 -c spire-server -- /opt/spire/bin/spire-server entry update \
    -entryID $ENTRYID \
    -parentID spiffe://example.org/spire-agent-node \
    -spiffeID spiffe://example.org/api \
    -selector k8s:container-name:api \
    -selector k8s:ns:api-ns \
    -dns symuser-invalid \
    -ttl 60

