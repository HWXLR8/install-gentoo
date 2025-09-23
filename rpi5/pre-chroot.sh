#!/bin/bash

set -euo pipefail

source ../common.sh
source config.sh


if ! (( NETBOOT )); then
    ./scripts/prepare-disk.sh
fi
./scripts/install-stage3.sh
./scripts/install-firmware.sh
./scripts/gentoo-chroot.sh
./scripts/unmount-chroot.sh
