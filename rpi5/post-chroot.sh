#!/bin/bash

set -euo pipefail

function log {
    RED='\033[0;31m'
    NC='\033[0m'
    echo -e "${RED}* ${1}${NC}"
}

log "env init"
source /etc/profile

log "syncing portage tree"
emerge-webrsync

log "setting root password"
passwd
log "creating unprivleged user"
read -p "Enter unprivleged username: " USERNAME
useradd -g users -G wheel,portage,audio,video,usb,cdrom -m $USERNAME
log "setting unprivleged password"
passwd $USERNAME

### LOCALE ###
log "setting locale"
echo 'LANG="en_US.UTF-8"' > /etc/env.d/02locale
echo 'LC_COLLATE="C"' >> /etc/env.d/02locale
echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
echo 'C.UTF8 UTF-8' >> /etc/locale.gen
log "generating locale"
locale-gen

### TIMEZONE ###
log "setting timezone"
ln -sf /usr/share/zoneinfo/Canada/Eastern /etc/localtime

### TMPFS ###
log "creating tmpfs for /tmp"
echo "tmpfs                    /tmp           tmpfs    defaults,noatime,nosuid,nodev,mode=1777,size=10240M 0 0" >> /etc/fstab

### PORTAGE ###
log "adding USE to make.conf"
echo 'USE="-systemd -selinux elogind"' >> /etc/portage/make.conf
log "adding ACCEPT_KEYWORDS to make.conf"
echo 'ACCEPT_KEYWORDS="~arm64 arm64"' >> /etc/portage/make.conf
log "adding VIDEO_CARDS to make.conf"
echo 'VIDEO_CARDS="v3d"' >> /etc/portage/make.conf

### MISC ###
# this stops the following error from spamming the term:
# INIT Id "f0" respawning too fast: disabled for 5 minutes
sudo sed -i '/^[[:space:]]*f0:/s/^/# /' /etc/inittab
