#!/bin/bash

ROOTD=/dev/nvme0n1
BOOTD=/dev/sda
BOOTP=/dev/sda1

# copy the above variables into post-chroot.sh
sed -i '3i\ROOTD='"$ROOTD"'\nBOOTD='"$BOOTD"'\n' post-chroot.sh

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

# check if user is root
if [ "$EUID" -ne 0 ]
then echo "please run as root"
     exit
fi

### install prerequisites ###
pacman -Sy wget

### format disk ###
lsblk
echo
echo -n -e "Gentoo will be installed onto the following disks:\n\n \
	$BOOTD	/boot\n\
	$ROOTD	/ \n\n"
confirm "continue?"
LOG "FORMATTING KEY DEVICE $BOOTD"
echo 'type=83' | sfdisk $BOOTD
lsblk -f
confirm "continue?"

### mkfs ###
LOG "CREATING VFAT FS ON KEY"
mkfs.vfat $BOOTP
LOG "CREATING LUKS FS ON ROOT"
cryptsetup luksFormat $ROOTD
LOG "OPENING ROOT DEVICE"
cryptsetup open $ROOTD root
LOG "CREATING EXT4 FS ON DECRYPTED ROOT"
mkfs.ext4 /dev/mapper/root
lsblk -f
confirm "continue?"

### download and verify stage3 tarball ###
TARBALL_ROOT_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-openrc/"
# curl and grep for latest tarball name
TARBALL_NAME=$(curl -s $TARBALL_ROOT_URL/latest-stage3-amd64-openrc.txt | grep stage3 | awk '{print $1}')
TARBALL_URL=$TARBALL_ROOT_URL/$TARBALL_NAME
DIGESTS_URL=$TARBALL_URL.DIGESTS
SIG_URL=$TARBALL_URL.asc
mkdir gentoo
LOG "MOUNTING ROOT"
mount /dev/mapper/root gentoo
lsblk -f
confirm "continue?"
cd gentoo
LOG "DOWNLOADING TARBALL"
wget $TARBALL_URL
wget $DIGESTS_URL
wget $SIG_URL
LOG "PRESENT WORKING DIR"
pwd
LOG "DIR CONTENTS"
ls -lh
confirm "continue?"
TARBALL=${TARBALL_URL##*/}
echo
LOG "********** DIGESTS FILE **********"
cat $TARBALL.DIGESTS
echo
LOG "********** COMPUTED DIGESTS **********"
sha512sum $TARBALL
echo
confirm "Do the above digests match up?"
# fetch all gentoo release keys
wget -O - https://qa-reports.gentoo.org/output/service-keys.gpg | gpg --import
echo
gpg --verify $TARBALL.asc
echo
echo -e "the gentoo release fingerprint is ${RED}13EBBDBEDE7A12775DFDB1BABB572E0E2D182910${NC}"
echo
confirm "Do the above fingerprints match up?"
echo
echo "everything checks out, proceed."
tar xpvf $TARBALL

### chroot ###
LOG "MOUNTING /boot"
mount $BOOTP boot
LOG "COPYING post-chroot.sh INTO CHROOT"
cp -v ../post-chroot.sh .
LOG "BEGIN CHROOT"
mount -t proc none proc
mount --rbind /sys sys
mount --make-rslave sys
mount --rbind /dev dev
mount --make-rslave dev
cp /etc/resolv.conf etc
chroot . /bin/bash
