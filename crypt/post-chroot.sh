#!/bin/bash

set -euo pipefail

source common.sh
source config.sh
set +u; source /etc/profile; set -u

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
emerge -a sys-kernel/gentoo-sources sys-kernel/linux-firmware sys-kernel/genkernel
log "ESELECT KERNEL"
eselect kernel list
confirm "is setting kernel option to 1 ok?"
eselect kernel set 1
cd /usr/src/linux
log "CONFIGURING KERNEL W/ localyesconfig"
make localyesconfig
# for docker support...
scripts/config --enable NETFILTER_XTABLES_LEGACY
scripts/config --enable IP_NF_IPTABLES
scripts/config --enable IP6_NF_IPTABLES
scripts/config --module IP_NF_NAT
scripts/config --module IP_NF_TARGET_MASQUERADE
scripts/config --module IP6_NF_NAT
scripts/config --module IP6_NF_TARGET_MASQUERADE
scripts/config --module IP_NF_RAW
scripts/config --module IP6_NF_RAW
make olddefconfig
# to save for future genkernel builds
cp .config /etc/kernels/kernel-config-$(make -s kernelrelease)
log "BUILDING KERNEL"
genkernel --lvm --luks --install --makeopts="-j$(nproc)" kernel

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
CRYPT_UUID=$(blkid -s UUID -o value "$CRYPTP")
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

### SYSLOG ###
log "INSTALLING SYSKLOGD"
emerge -a app-admin/sysklogd
rc-update add sysklogd default
rc-service sysklogd start

### USE FLAGS ###
log "SETTING USE FLAGS"
echo 'USE="wayland elogind -systemd -pulseaudio -selinux"' >> /etc/portage/make.conf

### GIT ###
log "INSTALLING GIT"
USE="-perl" emerge -a dev-vcs/git

### USER ENVIRONMENT ###
# everything below runs as $USERNAME (set by user_setup), not root, so nothing
# here ends up root-owned. quoted 'EOF' means ~ and $vars expand in the user's
# shell -- to pass a value in from this script, unquote it below and escape the
# vars you DON'T want expanded here.
log "SETTING UP USER ENVIRONMENT FOR $USERNAME"
su - $USERNAME <<-'EOF'
	set -euo pipefail

	mkdir -pv ~/src
	git clone https://github.com/HWXLR8/etc ~/src/etc
EOF

log "DONE"
