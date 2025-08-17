#!/bin/bash

set -euo pipefail

source "../common.sh"

DISK=/dev/sda

log "syncing portage tree"
emerge-webrsync
