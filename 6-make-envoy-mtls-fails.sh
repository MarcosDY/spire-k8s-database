#!/bin/bash

set -eu

. common.sh

${KUBECTL_PATH} exec -n spire spire-server-0 -c spire-server -- /opt/spire/bin/spire-server entry show \
  -spiffeID spiffe://example.org/api-proxy > /tmp/entryFound

ENTRYID=$( grep 'Entry ID         :' /tmp/entryFound | awk '{print $4}')

${KUBECTL_PATH} exec -n spire spire-server-0 -c spire-server -- /opt/spire/bin/spire-server entry update \
     -entryID $ENTRYID \
     -parentID spiffe://example.org/spire-agent-node \
     -spiffeID spiffe://example.org/api-proxy \
     -selector k8s:container-name:api-proxy-invalid \
     -selector k8s:ns:api-ns \
     -ttl 60
