#!/bin/bash

set -euo pipefail

source ../common.sh
source ./config.sh

log "partitioning $DISK"
parted -s $DISK mklabel msdos \
       mkpart primary fat32 1MiB 257MiB set 1 boot on \
       mkpart primary ext4 257MiB 100%

# format partitions
log "formatting ${DISK}1"
mkfs.vfat -F 32 "${DISK}1"
log "formatting ${DISK}2"
mkfs.ext4 -F "${DISK}2"

log "creating $ROOT if not exist"
mkdir -pv $ROOT
log "creating $WORK if not exist"
mkdir -pv $WORK
log "mounting ${DISK}2 to $ROOT"
mount ${DISK}2 $ROOT
log "mounting ${DISK}1 to $BOOT"
mount ${DISK}1 $BOOT
