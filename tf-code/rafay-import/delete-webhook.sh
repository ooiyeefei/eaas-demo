#!/usr/bin/env bash

# Scipt to delete rafay-drift-validate-v3 webhook.
#
# Expects following environment variables to be set:
# - RCTL_REST_ENDPOINT
# - RCTL_API_KEY
# - RCTL_API_SECRET

TMP_DIR=$(mktemp -d)
cd $TMP_DIR

ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
  ARCH="amd64"
elif [ "$ARCH" = "aarch64" ]; then
  ARCH="arm64"
fi

wget "https://rafay-prod-cli.s3-us-west-2.amazonaws.com/publish/rctl-linux-${ARCH}.tar.bz2"
tar -xf "rctl-linux-${ARCH}.tar.bz2"
./rctl download kubeconfig --cluster ${CLUSTER_NAME} -p ${PROJECT} > ztka-user-kubeconfig
export KUBECONFIG=ztka-user-kubeconfig
wget "https://dl.k8s.io/release/v1.31.0/bin/linux/${ARCH}/kubectl"
chmod +x kubectl
./kubectl delete validatingwebhookconfiguration rafay-drift-validate-v3

rm -rf $TMP_DIR
