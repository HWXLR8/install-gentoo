#!/bin/bash

set -euo pipefail

source ../common.sh

ROOTD=/dev/nvme0n1
ROOTP=/dev/nvme0n1p1

# copy the above variables into post-chroot.sh
sed -i '3i\ROOTD='"$ROOTD"'\n' post-chroot.sh

check_if_root

### install prerequisites ###
pacman -Sy wget

### format disk ###
lsblk
echo
echo -n -e "Gentoo will be installed onto the following disks:\n\n \
	$ROOTD	/ \n\n"
confirm "continue?"

### device format ###
log "FORMATTING ROOT DEVICE $ROOTD"
echo ',,83' | sfdisk $ROOTD
lsblk -f
confirm "continue?"

### mkfs ###
log "CREATING EXT4 FS ON ROOT DEVICE"
mkfs.ext4 $ROOTP
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
log "MOUNTING ROOT"
mount $ROOTP gentoo
lsblk -f
confirm "continue?"
cd gentoo
log "DOWNLOADING TARBALL"
wget $TARBALL_URL
wget $DIGESTS_URL
wget $SIG_URL
log "PRESENT WORKING DIR"
pwd
log "DIR CONTENTS"
ls -lh
confirm "continue?"
TARBALL=${TARBALL_URL##*/}
echo
log "********** DIGESTS FILE **********"
cat $TARBALL.DIGESTS
echo
log "********** COMPUTED DIGESTS **********"
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
log "COPYING post-chroot.sh INTO CHROOT"
cp -v ../post-chroot.sh .
log "BEGIN CHROOT"
mount -t proc none proc
mount --rbind /sys sys
mount --make-rslave sys
mount --rbind /dev dev
mount --make-rslave dev
cp /etc/resolv.conf etc
chroot . /bin/bash
