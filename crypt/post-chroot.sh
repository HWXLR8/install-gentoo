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
log "INSTALLING GENKERNEL"
emerge -a genkernel
log "GENERATING INITRAMFS WITH LUKS SUPPORT"
genkernel --lvm --luks --install kernel

### INITRAMFS ###
log "INSTALLING DRACUT+CRYPTSETUP"
emerge -a dracut cryptsetup
KVER=$(make -s kernelrelease)
log "INSTALLING INITRAMFS"
dracut --kver "$KVER" --force --add crypt

### GRUB ###
log "WRITING GRUB CONFIG TO make.conf"
echo 'GRUB_PLATFORMS="i386-pc"' >> /etc/portage/make.conf
log "INSTALLING GRUB"
emerge -a sys-boot/grub
grub-install --target=i386-pc $BOOTD
log "SETTING LINUX COMMAND LINE ARGUMENTS FOR BOOT"
CRYPT_UUID=$(blkid -s UUID -o value "$ROOTD")
log "$CRYPT_UUID"
confirm "does the above UUID look sane?"
sed -i "s|^#\?GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"rd.luks.uuid=${CRYPT_UUID} rd.luks.allow-discards\"|" /etc/default/grub
log "GENERATING GRUB CFG"
grub-mkconfig -o /boot/grub/grub.cfg
log "INSTALLING DHCP CLIENT"
emerge -a net-misc/dhcpcd

### ACCEPT_KEYWORDS ###
log "SETTING ACCEPT_KEYWORDS"
echo 'ACCEPT_KEYWORDS="amd64 ~amd64"' >> /etc/portage/make.conf

### CPU FLAGS ###
log "SETTING CPU FLAGS"
emerge -a app-portage/cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/cpu-flags

ntp_setup
sudo_setup

log "DONE"
