#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- ACTION REQUIRED ---
# Find the correct download URL for the rctl ARM64 binary from Rafay's
# official documentation and paste it here.
# It will look something like "https://.../rctl-linux-arm64.tar.bz2"
RCTL_ARM64_URL="<PASTE THE CORRECT URL FOR ARM64 RCTL HERE>"
# --- END ACTION ---


TMP_DIR=$(mktemp -d)
cd $TMP_DIR

ARCH=$(uname -m)
K8S_ARCH=""
RCTL_URL=""

if [ "$ARCH" = "aarch64" ]; then
  echo "Detected ARM64 architecture."
  K8S_ARCH="arm64"
  RCTL_URL="${RCTL_ARM64_URL}"
else
  echo "Detected AMD64 architecture."
  K8S_ARCH="amd64"
  RCTL_URL="https://rafay-prod-cli.s3-us-west-2.amazonaws.com/publish/rctl-linux-amd64.tar.bz2"
fi

if [ -z "$RCTL_URL" ] || [ "$RCTL_URL" = "<PASTE THE CORRECT URL FOR ARM64 RCTL HERE>" ]; then
  echo "Error: The download URL for the ARM64 rctl binary has not been set in the script."
  echo "Please find the correct URL from the Rafay documentation and update the RCTL_ARM64_URL variable."
  exit 1
fi

echo "Downloading rctl from: ${RCTL_URL}"
wget -O rctl-linux.tar.bz2 "${RCTL_URL}"
tar -xf rctl-linux.tar.bz2

echo "Downloading kubectl for ${K8S_ARCH}..."
wget "https://dl.k8s.io/release/v1.31.0/bin/linux/${K8S_ARCH}/kubectl"
chmod +x kubectl

echo "Setting up kubeconfig for cluster '${CLUSTER_NAME}' in project '${PROJECT}'..."
./rctl download kubeconfig --cluster "${CLUSTER_NAME}" -p "${PROJECT}" > ztka-user-kubeconfig
export KUBECONFIG=ztka-user-kubeconfig

# Check if the webhook exists before trying to delete it
if ./kubectl get validatingwebhookconfiguration rafay-drift-validate-v3 --ignore-not-found; then
  echo "Webhook 'rafay-drift-validate-v3' found. Deleting..."
  ./kubectl delete validatingwebhookconfiguration rafay-drift-validate-v3
else
  echo "Webhook 'rafay-drift-validate-v3' not found. Skipping deletion."
fi

echo "Cleanup complete."
rm -rf $TMP_DIR
