#!/bin/bash

set -euo pipefail

source "../common.sh"

DISK=/dev/sda

log "syncing portage tree"
emerge-webrsync
log "emerge kernel sources and firmware"
echo "sys-boot/raspberrypi-firmware raspberrypi-videocore-bin" >> /etc/portage/package.license
echo "sys-kernel/raspberrypi-image raspberrypi-videocore-bin" >> /etc/portage/package.license
emerge -a \
       sys-kernel/raspberrypi-sources \
       sys-boot/raspberrypi-firmware \
       sys-kernel/raspberrypi-image
