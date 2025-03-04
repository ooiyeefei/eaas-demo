#!/bin/sh

set -o errexit

entry_id="IPv4 Intel(R) Ethernet Controller"
echo "Finding boot entry for '${entry_id}'."
# Find the boot number for the entry containing "IPv4 Intel(R) Ethernet Controller"
boot_number=$(efibootmgr | grep "${entry_id}" | awk '{sub(/^Boot/, ""); print $1}' | tr -d '*')
if [ -z "${boot_number}" ]; then
    echo "No boot entry found for '${entry_id}'."
    # On some systems like VMs, efibootmgr can't do anything. So we
    # just exit.
    exit
fi

echo "Setting the BootNext to ${boot_number} and powering off the machine!"
sudo efibootmgr --bootnext "${boot_number}"
sudo systemctl poweroff
