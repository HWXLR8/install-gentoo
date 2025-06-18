#!/bin/bash

set -euo pipefail

source "../common.sh"

WORK=/tmp/gentoo
DISK=/dev/sda
GENTOO=/mnt/gentoo

function prepare_disk {
    log "partitioning $DISK"
    parted -s $DISK mklabel msdos \
           mkpart primary fat32 1MiB 257MiB set 1 boot on \
           mkpart primary ext4 257MiB 100%

    # format partitions
    log "formatting ${DISK}1"
    mkfs.vfat -F 32 "${DISK}1"
    log "formatting ${DISK}2"
    mkfs.ext4 -F "${DISK}2"

    log "creating $GENTOO if not exist"
    mkdir -pv $GENTOO
    log "creating $WORK if not exist"
    mkdir -pv $WORK
    log "mounting ${DISK}2 to $GENTOO"
    mount ${DISK}2 $GENTOO
}

function download_stage3 {
    ROOT_URL="https://distfiles.gentoo.org/releases/arm64/autobuilds/current-stage3-arm64-openrc/"
    NAME=$(curl -s ${ROOT_URL}latest-stage3-arm64-openrc.txt | grep stage3 | awk '{print $1}')
    URL=${ROOT_URL}${NAME}
    log "downloading tarball"
    wget -P $WORK ${URL} ${URL}.DIGESTS ${URL}.asc
    log "contents:"; ls -lh $WORK
    confirm "look good?"
    TARBALL=${URL##*/}
    log "DIGESTS FILE"; cat $WORK/${TARBALL}.DIGESTS
    log "COMPUTED DIGESTS"; sha512sum $WORK/${TARBALL}
    confirm "do digests match?"
    wget -O - https://qa-reports.gentoo.org/output/service-keys.gpg | gpg --import
    gpg --verify $WORK/${TARBALL}.asc
    log "Gentoo release fingerprint: 13EBBDBEDE7A12775DFDB1BABB572E0E2D182910"
    confirm "do fingerprints match?"
    tar xpvf $WORK/${TARBALL} -C $GENTOO/
}

function download_gentoo_snapshot {
    URL="https://distfiles.gentoo.org/snapshots"
    # SNAPSHOT="gentoo-latest.tar.xz"
    SNAPSHOT="gentoo-20250616.tar.xz"
    cd $WORK
    log "downloading latest gentoo snapshot from $URL/$SNAPSHOT"
    wget "$URL/$SNAPSHOT"
    wget "$URL/$SNAPSHOT.md5sum"
    wget "$URL/$SNAPSHOT.gpgsig"
    log "directory contents:"; ls -lh
    confirm "look good?"
    log "verifying snapshot"
    md5sum -c "$SNAPSHOT.md5sum"
    gpg --verify "$SNAPSHOT.gpgsig" "$WORK/$SNAPSHOT"
    log "Gentoo ebuild repository fingerprint: DCD0 5B71 EAB9 4199 527F 44AC DB6B 8C1F 96D8 BF6D"
    confirm "do fingerprints match?"
    mkdir -pv ${GENTOO}/var/db/repos/gentoo
    tar xpvf "$SNAPSHOT" --strip-components=1 -C ${GENTOO}/var/db/repos/gentoo
}

function gentoo-chroot {
    cd $GENTOO
    log "mounting /boot"
    mount ${DISK}1 boot
    log "copying post-chroot.sh into chroot"
    cp -v ../post-chroot.sh .
    log "begin chroot"
    mount -t proc none proc
    mount --rbind /sys sys
    mount --make-rslave sys
    mount --rbind /dev dev
    mount --make-rslave dev
    cp /etc/resolv.conf etc
    chroot . /bin/bash
}

prepare_disk
download_stage3
### download_gentoo_snapshot
gentoo-chroot
