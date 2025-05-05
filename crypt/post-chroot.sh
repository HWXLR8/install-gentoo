#!/bin/bash

# colors
RED='\033[0;31m'
NC='\033[0m'

function confirm {
    read -p "$1 [y/N] " -r
    if ! [[ $REPLY =~ ^[Yy]$ ]]; then
	echo "quitting"
	exit
    fi
}

function LOG {
    echo -e "${RED}${1}${NC}"
}

### ENV INIT ###
source /etc/profile

### PORTAGE TREE ###
LOG "SYNCING PORTAGE TREE"
emerge-webrsync

### USER ###
LOG "SET ROOT PASSWORD"
passwd
LOG "CREATING UNPRIVLEGED USER"
read -p "Enter unprivleged username: " USERNAME
useradd -g users -G wheel,portage,audio,video,usb,cdrom -m $USERNAME
LOG "SET UNPRIVLEGED USER PASSWORD"
passwd $USERNAME

### LOCALE ###
LOG "SETTING LOCALE"
echo 'LANG="en_US.UTF-8"' > /etc/env.d/02locale
echo 'LC_COLLATE="C"' >> /etc/env.d/02locale
echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
echo 'C.UTF8 UTF-8' >> /etc/locale.gen
LOG "GENERATING LOCALE"
locale-gen

### HOSTNAME ###
LOG "SET HOST NAME"
read -p "Enter hostname: " HOST
echo "$HOST" > /etc/hostname

### TIMEZONE ###
LOG "SETTING TIMEZONE"
ln -sf /usr/share/zoneinfo/Canada/Eastern /etc/localtime

### DNS ###
LOG "SETTING DNS"
echo "nameserver 9.9.9.9" > /etc/resolv.conf.head

### TMPS ###
LOG "SETTING TMPFS for /tmp"
echo "tmpfs                    /tmp           tmpfs    defaults,noatime,nosuid,nodev,mode=1777,size=10240M 0 0" >> /etc/fstab

### KERNEL ###
LOG "UNMASKING sys-kernel/linux-firmware"
echo 'sys-kernel/linux-firmware linux-fw-redistributable' > /etc/portage/package.license
LOG "EMERGE KERNEL SOURCES/FW"
emerge -a sys-kernel/gentoo-sources sys-kernel/linux-firmware
LOG "ESELECT KERNEL"
eselect kernel list
confirm "is setting kernel option to 1 ok?"
eselect kernel set 1
cd /usr/src/linux
LOG "CONFIGURING KERNEL W/ localyesconfig"
make localyesconfig
LOG "INSTALLING GENKERNEL"
emerge -a genkernel
LOG "GENERATING INITRAMFS WITH LUKS SUPPORT"
genkernel --lvm --luks --install kernel

### INITRAMFS ###
LOG "INSTALLING DRACUT/CRYPTSETUP"
emerge -a dracut
KVER=$(make -s kernelrelease)
LOG "INSTALLING INITRAMFS"
dracut --kver "$KVER" --force --add crypt

### GRUB ###
LOG "WRITING GRUB CONFIG TO make.conf"
echo 'GRUB_PLATFORMS="i386-pc"' >> /etc/portage/make.conf
LOG "INSTALLING GRUB"
emerge -a sys-boot/grub
grub-install --target=i386-pc $BOOTD
LOG "SETTING LINUX COMMAND LINE ARGUMENTS FOR BOOT"
CRYPT_UUID=$(blkid $ROOTD | awk '{print $2}')
LOG "$CRYPT_UUID"
confirm "does the above UUID look sane?"
sed -i "/^GRUB_CMDLINE_LINUX=/c\GRUB_CMDLINE_LINUX=\"rd.luks.uuid=$CRYPT_UUID rd.luks.allow-discards\"" /etc/default/grub
LOG "GENERATING GRUB CFG"
grub-mkconfig -o /boot/grub/grub.cfg
LOG "INSTALLING DHCP CLIENT"
emerge -a net-misc/dhcpcd

### ACCEPT_KEYWORDS ###
LOG "SETTING ACCEPT_KEYWORDS"
echo 'ACCEPT_KEYWORDS="amd64 ~amd64"' >> /etc/portage/make.conf

### CPU FLAGS ###
LOG "SETTING CPU FLAGS"
emerge -a app-portage/cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/cpu-flags

LOG "DONE"
