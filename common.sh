#!/bin/bash

# Installation env vars
KIND_PATH=./bin/kind
KUBECTL_PATH=./bin/kubectl

# Configuration env vars
CLUSTER_NAME=spire-cluster 

norm=$(tput sgr0) || true
red=$(tput setaf 1) || true
green=$(tput setaf 2) || true
yellow=$(tput setaf 3) || true
bold=$(tput bold) || true

timestamp() {
    date -u "+[%Y-%m-%dT%H:%M:%SZ]"
}

log-info() {
    echo "${bold}$(timestamp) $*${norm}"
}

log-warn() {
    echo "${yellow}$(timestamp) $*${norm}"
}

log-success() {
    echo "${green}$(timestamp) $*${norm}"
}

log-debug() {
    echo "${norm}$(timestamp) $*"
}

fail-now() {
    echo "${red}$(timestamp) $*${norm}"
    exit 1
}

