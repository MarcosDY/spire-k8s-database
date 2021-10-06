#!/bin/bash

set -eu

. common.sh

podName=$(${KUBECTL_PATH} get pod -n client-ns -l app=client -o jsonpath="{.items[0].metadata.name}")

${KUBECTL_PATH} exec -n client-ns $podName -c client -- ./client customer list || log-info "error"

