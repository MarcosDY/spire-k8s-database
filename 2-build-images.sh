#!/bin/bash

. common.sh

log-info "building spiffe-helper"
docker build --target spiffe-helper -t spiffe-helper .
docker tag spiffe-helper:latest spiffe-helper:latest-local

log-info "building client service"
docker build --target client-service -t client-service .
docker tag client-service:latest client-service:latest-local

log-info "building api service"
docker build --target api-service -t api-service .
docker tag api-service:latest api-service:latest-local

