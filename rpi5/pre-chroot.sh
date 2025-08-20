#!/bin/bash

set -euo pipefail

source "../common.sh"

NETBOOT=1
WORK=/tmp/gentoo
DISK=/dev/sda
GENTOO=/mnt/gentoo

CONFIG=$(cat <<'EOF'
# have a properly sized image
disable_overscan=1

# Enable audio (loads snd_bcm2835)
dtparam=audio=on

# Enable DRM VC4 V3D driver
dtoverlay=vc4-kms-v3d-pi5
EOF
)

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

function install_stage3 {
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
    log "Gentoo release fingerprint: 13EB BDBE DE7A 1277 5DFD B1BA BB57 2E0E 2D18 2910"
    confirm "do fingerprints match?"
    tar xpvf $WORK/${TARBALL} -C $GENTOO/
}

function download_gentoo_snapshot {
    URL="https://distfiles.gentoo.org/snapshots"
    # SNAPSHOT="gentoo-latest.tar.xz"
    SNAPSHOT="gentoo-20250819.tar.xz"
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

function install_firmware {
    log "mounting /boot"
    mount ${DISK}1 $GENTOO/boot
    cd $WORK

    git clone --depth=1 https://github.com/raspberrypi/firmware.git
    cp -v firmware/boot/bcm2712-rpi-5-b.dtb ${GENTOO}/boot/
    cp -v firmware/boot/fixup_cd.dat ${GENTOO}/boot/
    cp -v firmware/boot/fixup.dat ${GENTOO}/boot/
    cp -v firmware/boot/start_cd.elf ${GENTOO}/boot/
    cp -v firmware/boot/start.elf ${GENTOO}/boot/
    cp -v firmware/boot/bootcode.bin ${GENTOO}/boot/
    cp -v firmware/boot/kernel8.img ${GENTOO}/boot/
    cp -rv firmware/boot/overlays ${GENTOO}/boot/

    log "writing cmdline.txt"
    echo "dwc_otg.lpm_enable=0 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 rootwait net.ifnames=0 logo.nologo usbhid.mousepoll=1" >> ${GENTOO}/boot/cmdline.txt

    log "writing config.txt"
    echo "$CONFIG" | tee -a ${GENTOO}/boot/config.txt

    log "copying firmware"
    cp -rv firmware/modules ${GENTOO}/lib/

    # wifi firmware
    log "installing wifi fw"
    git clone --depth=1 https://github.com/RPi-Distro/firmware-nonfree.git
    mkdir -pv ${GENTOO}/lib/firmware/brcm
    cp -v firmware-nonfree/debian/config/brcm80211/cypress/cyfmac43455-sdio-standard.bin ${GENTOO}/lib/firmware/brcm/
    cp -v firmware-nonfree/debian/config/brcm80211/cypress/cyfmac43455-sdio.clm_blob ${GENTOO}/lib/firmware/brcm/
    cp -v firmware-nonfree/debian/config/brcm80211/brcm/brcmfmac43455-sdio.txt ${GENTOO}/lib/firmware/brcm/
    log "symlinking firmware files"
    cd ${GENTOO}/lib/firmware/brcm/
    ln -vs cyfmac43455-sdio-standard.bin brcmfmac43455-sdio.raspberrypi,5-model-b.bin
    ln -vs cyfmac43455-sdio.clm_blob brcmfmac43455-sdio.raspberrypi,5-model-b.clm_blob
    ln -vs brcmfmac43455-sdio.txt brcmfmac43455-sdio.raspberrypi,5-model-b.txt
    cd $WORK
    ls -l ${GENTOO}/lib/firmware/brcm/
    confirm "symlinks look good?"

    # bluetooth
    log "installing bluetooth firmware"
    git clone --depth=1 https://github.com/RPi-Distro/bluez-firmware.git
    mkdir -pv ${GENTOO}/lib/firmware/brcm
    cp bluez-firmware/debian/firmware/broadcom/BCM4345C0.hcd ${GENTOO}/lib/firmware/brcm/
    log "symlinking firmware files"
    cd ${GENTOO}/lib/firmware/brcm/
    ln -sv BCM4345C0.hcd BCM4345C0.raspberrypi,5-model-b.hcd
    cd $WORK
}

function gentoo-chroot {
    log "copying post-chroot.sh into chroot"
    cp -v post-chroot.sh $GENTOO
    log "begin chroot"
    cd $GENTOO
    mount -t proc none proc
    mount --rbind /sys sys
    mount --make-rslave sys
    mount --rbind /dev dev
    mount --make-rslave dev
    cp /etc/resolv.conf etc
    chroot . /bin/bash
}

function unmount-chroot {
    log "unmounting dev/sys/proc"
    umount -l dev
    umount -l sys
    umount -l proc
}

if ! (( NETBOOT )); then
    prepare_disk
fi

install_stage3
# install_firmware
gentoo-chroot
unmount-chroot
