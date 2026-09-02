#!/bin/bash

### EDIT THESE ###
DETACHED_BOOT=1      # 1 = /boot on removable key, 0 = /boot on the root disk
ROOTD=/dev/nvme0n1   # disk holding the encrypted root
KEYD=/dev/sda        # removable boot key; ignored when DETACHED_BOOT=0

### derived ###
if (( DETACHED_BOOT )); then
    BOOTD=$KEYD                 # grub-install target: the key device
    BOOTP=${KEYD}1              # sd*-style: bare number suffix
    CRYPTP=$ROOTD               # whole disk is the LUKS container
else
    BOOTD=$ROOTD                # grub-install target: the root disk itself
    BOOTP=${ROOTD}p1            # nvme-style: 'p' number suffix
    CRYPTP=${ROOTD}p2
fi

ROOT=/dev/mapper/root
WORK=gentoo                     # staging mount point, relative to crypt/
