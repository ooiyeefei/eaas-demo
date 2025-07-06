#!/usr/bin/env bash

# Scipt to delete rafay-drift-validate-v3 webhook.
#
# Expects following environment variables to be set:
# - RCTL_REST_ENDPOINT
# - RCTL_API_KEY
# - RCTL_API_SECRET

set -e # Exit immediately if a command exits with a non-zero status.

TMP_DIR=$(mktemp -d)
cd $TMP_DIR

ARCH=$(uname -m)
RCTL_ARCH_SUFFIX="amd64" # Default to amd64

if [ "$ARCH" = "aarch64" ]; then
  ARCH="arm64"
  # Correct the filename for the ARM64 architecture
  RCTL_ARCH_SUFFIX="armv7"
fi

echo "Detected architecture: ${ARCH}. Using rctl suffix: ${RCTL_ARCH_SUFFIX}"

wget "https://rafay-prod-cli.s3-us-west-2.amazonaws.com/publish/rctl-linux-${RCTL_ARCH_SUFFIX}.tar.bz2"
tar -xf "rctl-linux-${RCTL_ARCH_SUFFIX}.tar.bz2"

./rctl download kubeconfig --cluster ${CLUSTER_NAME} -p ${PROJECT} > ztka-user-kubeconfig
export KUBECONFIG=ztka-user-kubeconfig

wget "https://dl.k8s.io/release/v1.31.0/bin/linux/${ARCH}/kubectl"
chmod +x kubectl

# Check if the webhook exists before trying to delete it
if ./kubectl get validatingwebhookconfiguration rafay-drift-validate-v3 > /dev/null 2>&1; then
  echo "Webhook 'rafay-drift-validate-v3' found. Deleting..."
  ./kubectl delete validatingwebhookconfiguration rafay-drift-validate-v3
else
  echo "Webhook 'rafay-drift-validate-v3' not found. Skipping deletion."
fi

rm -rf $TMP_DIR
