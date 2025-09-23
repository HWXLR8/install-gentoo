#!/bin/bash

set -euo pipefail

source ../../common.sh
source ../config.sh

cd $WORK

git clone --depth=1 https://github.com/raspberrypi/firmware.git
# rasberry pi SBC
cp -v firmware/boot/bcm2712-rpi-5-b.dtb $BOOT
# rasberry pi CM5 lite
cp -v firmware/boot/bcm2712-rpi-cm5l-cm5io.dtb $BOOT
cp -v firmware/boot/fixup_cd.dat $BOOT
cp -v firmware/boot/fixup.dat $BOOT
cp -v firmware/boot/start_cd.elf $BOOT
cp -v firmware/boot/start.elf $BOOT
cp -v firmware/boot/bootcode.bin $BOOT
cp -v firmware/boot/kernel8.img $BOOT
cp -rv firmware/boot/overlays $BOOT

log "writing cmdline.txt"
if (( NETBOOT )); then
    envsubst < ../cmdline-netboot.txt > ${BOOT}/cmdline.txt
else
    cp -v ../cmdline-bare-metal.txt ${BOOT}/cmdline.txt
fi

log "writing config.txt"
cp -v ../config.txt $BOOT

log "copying firmware"
cp -rv firmware/modules $ROOT/lib/

# wifi firmware
log "installing wifi fw"
git clone --depth=1 https://github.com/RPi-Distro/firmware-nonfree.git
mkdir -pv ${ROOT}/lib/firmware/brcm
cp -v firmware-nonfree/debian/config/brcm80211/cypress/cyfmac43455-sdio-standard.bin ${ROOT}/lib/firmware/brcm/
cp -v firmware-nonfree/debian/config/brcm80211/cypress/cyfmac43455-sdio.clm_blob ${ROOT}/lib/firmware/brcm/
cp -v firmware-nonfree/debian/config/brcm80211/brcm/brcmfmac43455-sdio.txt ${ROOT}/lib/firmware/brcm/
log "symlinking firmware files"
cd ${ROOT}/lib/firmware/brcm/
ln -vs cyfmac43455-sdio-standard.bin brcmfmac43455-sdio.raspberrypi,5-model-b.bin
ln -vs cyfmac43455-sdio.clm_blob brcmfmac43455-sdio.raspberrypi,5-model-b.clm_blob
ln -vs brcmfmac43455-sdio.txt brcmfmac43455-sdio.raspberrypi,5-model-b.txt
cd $WORK
ls -l ${ROOT}/lib/firmware/brcm/
confirm "symlinks look good?"

# bluetooth
log "installing bluetooth firmware"
git clone --depth=1 https://github.com/RPi-Distro/bluez-firmware.git
mkdir -pv ${ROOT}/lib/firmware/brcm
cp bluez-firmware/debian/firmware/broadcom/BCM4345C0.hcd ${ROOT}/lib/firmware/brcm/
log "symlinking firmware files"
cd ${ROOT}/lib/firmware/brcm/
ln -sv BCM4345C0.hcd BCM4345C0.raspberrypi,5-model-b.hcd
