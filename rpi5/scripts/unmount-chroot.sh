#!/bin/bash

set -euo pipefail

source ../../common.sh
source ../config.sh

log "unmounting dev/sys/proc"
umount -l dev
umount -l sys
umount -l proc
