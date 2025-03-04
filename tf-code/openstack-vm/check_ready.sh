#!/bin/sh

# Check if cloud-init is installed
if ! which cloud-init > /dev/null 2>&1; then
  echo "cloud-init is not installed, assuming machine is already initialized."
  exit 0
fi

# cloud-init is installed, check its status
echo "cloud-init is installed, waiting for initialization to complete..."
if ! timeout 10m cloud-init status --long --wait; then
  echo "cloud-init failed or timed out"
  exit 1
fi

echo "cloud-init succeeded."
