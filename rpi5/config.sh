#!/bin/bash

# NETBOOTING REQUIRES ALL OF THESE
NETBOOT=1
NETPATH="" # NO trailing /
SN=""
NET_IP=""

DISK=/dev/sda
WORK=/tmp/gentoo

if (( NETBOOT )); then
    ROOT=${NETPATH}/${SN}-root
    BOOT=${NETPATH}/$SN
else
    ROOT=/mnt/gentoo
    BOOT=${ROOT}/boot
fi
