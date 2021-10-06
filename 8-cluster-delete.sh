#!/bin/bash

. common.sh

${KIND_PATH} delete cluster --name ${CLUSTER_NAME}
