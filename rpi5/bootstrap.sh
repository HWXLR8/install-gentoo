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

### make.conf ###
log "adding USE to make.conf"
echo 'USE="-systemd -selinux elogind"' >> /etc/portage/make.conf
log "adding ACCEPT_KEYWORDS to make.conf"
echo 'ACCEPT_KEYWORDS="~arm64 arm64"' >> /etc/portage/make.conf
log "adding VIDEO_CARDS to make.conf"
echo 'VIDEO_CARDS="v3d"' >> /etc/portage/make.conf
