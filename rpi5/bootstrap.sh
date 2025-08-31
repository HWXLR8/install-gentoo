#!/bin/bash

set -euo pipefail

function log {
    RED='\033[0;31m'
    NC='\033[0m'
    echo -e "${RED}* ${1}${NC}"
}

### sudo ###
log "emerging sudo"
USE="-sendmail" emerge sudo
log "modifying /etc/sudoers"
sed -i '/%wheel ALL=(ALL:ALL) ALL/ s/^[[:space:]]*#[[:space:]]*//' /etc/sudoers
