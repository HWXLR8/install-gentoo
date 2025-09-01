#!/bin/bash

set -euo pipefail

source ../common.sh
source ./config.sh


if ! (( NETBOOT )); then
    ./prepare-disk.sh
fi
./install-stage3.sh
./install-firmware.sh
./gentoo-chroot.sh
./unmount-chroot.sh
