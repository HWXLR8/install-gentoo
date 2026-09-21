#!/bin/bash

set -euo pipefail

source ../common.sh
source config.sh

### format disk ###
lsblk
echo
if (( DETACHED_BOOT )); then
	echo -n -e "Gentoo will be installed onto the following disks:\n\n \
	$BOOTP	/boot	(detached key)\n\
	$CRYPTP	/	(luks)\n\n"
else
	echo -n -e "Gentoo will be installed onto the following disk:\n\n \
	$BOOTP	/boot\n\
	$CRYPTP	/	(luks)\n\n"
fi
confirm "continue?"

### partition ###
if (( DETACHED_BOOT )); then
	log "FORMATTING KEY DEVICE $BOOTD"
	echo 'type=83' | sfdisk $BOOTD
else
	log "FORMATTING ROOT DEVICE $BOOTD"
	sfdisk $BOOTD <<-'EOF'
	label: dos
	,256M,83,*
	,,83
	EOF
fi
lsblk -f
confirm "continue?"

### mkfs ###
if (( DETACHED_BOOT )); then
	log "CREATING VFAT FS ON KEY"
	mkfs.vfat $BOOTP
else
	log "CREATING EXT4 FS ON BOOT PARTITION"
	mkfs.ext4 $BOOTP
fi
log "CREATING LUKS FS ON ROOT"
cryptsetup luksFormat $CRYPTP
log "OPENING ROOT DEVICE"
cryptsetup open $CRYPTP root
log "CREATING EXT4 FS ON DECRYPTED ROOT"
mkfs.ext4 $ROOT
lsblk -f
confirm "continue?"

### download and verify stage3 tarball ###
TARBALL_ROOT_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-openrc/"
# curl and grep for latest tarball name
TARBALL_NAME=$(curl -s $TARBALL_ROOT_URL/latest-stage3-amd64-openrc.txt | grep stage3 | awk '{print $1}')
TARBALL_URL=$TARBALL_ROOT_URL/$TARBALL_NAME
DIGESTS_URL=$TARBALL_URL.DIGESTS
SIG_URL=$TARBALL_URL.asc
mkdir $WORK
log "MOUNTING ROOT"
mount $ROOT $WORK
lsblk -f
confirm "continue?"
cd $WORK
log "DOWNLOADING TARBALL"
curl -fLO $TARBALL_URL
curl -fLO $DIGESTS_URL
curl -fLO $SIG_URL
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
curl -fsSL https://qa-reports.gentoo.org/output/service-keys.gpg | gpg --import
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
log "MOUNTING /boot"
mount $BOOTP boot
gentoo_chroot
