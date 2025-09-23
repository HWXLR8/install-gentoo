#!/bin/bash

set -euo pipefail

source ../../common.sh
source ../config.sh

log "copying post-chroot.sh into chroot"
cp -v ../post-chroot.sh $ROOT
log "begin chroot"
cd $ROOT
mount -t proc none proc
mount --rbind /sys sys
mount --make-rslave sys
mount --rbind /dev dev
mount --make-rslave dev
cp /etc/resolv.conf etc
chroot . /bin/bash
