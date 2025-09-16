#!/bin/bash

set -euo pipefail

source ../common.sh
source /etc/profile

sync_portage
user_setup
locale_setup
hostname_setup
timezone_setup
tmpfs_setup

### PORTAGE ###
log "adding USE to make.conf"
echo 'USE="-systemd -selinux elogind"' >> /etc/portage/make.conf
log "adding ACCEPT_KEYWORDS to make.conf"
echo 'ACCEPT_KEYWORDS="~arm64 arm64"' >> /etc/portage/make.conf
log "adding VIDEO_CARDS to make.conf"
echo 'VIDEO_CARDS="v3d"' >> /etc/portage/make.conf

ntp_setup
sudo_setup

### MISC ###
# this stops the following error from spamming the term:
# INIT Id "f0" respawning too fast: disabled for 5 minutes
sudo sed -i '/^[[:space:]]*f0:/s/^/# /' /etc/inittab
