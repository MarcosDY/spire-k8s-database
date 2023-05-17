#!/bin/bash

. common.sh

download-bin() {
    local bin_path=$1
    local bin_url=$2
    if [ ! -f "${bin_path}" ] ; then
        log-info "downloading $(basename ${bin_path}) from ${bin_url}..."
        curl -# -f -Lo "${bin_path}" "${bin_url}"
        chmod +x "${bin_path}"
    fi
}

download-kind() {
    KINDVERSION=v0.19.0
    KINDPATH=$(command -v kind || echo)
    UNAME=$(uname | awk '{print tolower($0)}')
    KINDURL="https://github.com/kubernetes-sigs/kind/releases/download/$KINDVERSION/kind-$UNAME-amd64"

    local kind_path=$1
    # Ensure kind exists at the expected version
    if [ -x "${KINDPATH}" ] && "${KINDPATH}" version | grep -q "${KINDVERSION}"; then
        ln -s "${KINDPATH}" "${kind_path}"
    else
        download-bin "${kind_path}" "${KINDURL}"
    fi
}

download-kubectl() {
    KUBECTLVERSION=v1.27.1
    KUBECTLPATH=$(command -v kubectl || echo)
    UNAME=$(uname | awk '{print tolower($0)}')
    KUBECTLURL="https://storage.googleapis.com/kubernetes-release/release/$KUBECTLVERSION/bin/$UNAME/amd64/kubectl"

    local kubectl_path=$1
    # Ensure kubectl exists at the expected version
    if [ -x "${KUBECTLPATH}" ] && "${KUBECTLPATH}" version --short --client=true | grep -q "${KUBECTLVERSION}"; then
        ln -s "${KUBECTLPATH}" "${kubectl_path}"
    else
        download-bin "${kubectl_path}" "${KUBECTLURL}"
    fi
}

mkdir -p ./bin

# Download kind at the expected version at the given path.
download-kind "${KIND_PATH}"

# Download kubectl at the expected version.
download-kubectl "${KUBECTL_PATH}"

# We must supply an absolute path to the configuration directory. Replace the
# CONFDIR variable in the kind configuration with the conf directory of the 
# running test.
sed -i.yaml "s#CONFDIR#${PWD}/k8s/kind#g" k8s/kind/config

# Starting cluster
# TODO: move to vars
${KIND_PATH} create cluster --name ${CLUSTER_NAME} --config ./k8s/kind/config.yaml

