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

### KERNEL ###
log "UNMASKING sys-kernel/linux-firmware"
echo 'sys-kernel/linux-firmware linux-fw-redistributable' > /etc/portage/package.license
log "EMERGE KERNEL SOURCES/FW"
emerge -a sys-kernel/gentoo-sources sys-kernel/linux-firmware
log "ESELECT KERNEL"
eselect kernel list
confirm "is setting kernel option to 1 ok?"
eselect kernel set 1
cd /usr/src/linux
log "CONFIGURING KERNEL W/ localyesconfig"
make localyesconfig
# make -j$(nproc)
# make modules_install
# make install
# confirm "continue?"

### INITRAMFS ###
log "INSTALLING GENKERNEL"
emerge -a genkernel
log "GENERATING INITRAMFS WITH LUKS SUPPORT"
genkernel --lvm --luks --install all

### GRUB ###
log "WRITING GRUB CONFIG TO make.conf"
echo 'GRUB_PLATFORMS="i386-pc"' >> /etc/portage/make.conf
log "INSTALLING GRUB"
emerge -a sys-boot/grub
grub-install --target=i386-pc $ROOTD
log "GENERATING GRUB CFG"
grub-mkconfig -o /boot/grub/grub.cfg
log "INSTALLING DHCP CLIENT"
emerge -a net-misc/dhcpcd

ntp_setup
sudo_setup

log "DONE"
