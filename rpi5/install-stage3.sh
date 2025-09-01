#!/bin/bash

set -euo pipefail

source ../common.sh
source ./config.sh

ROOT_URL="https://distfiles.gentoo.org/releases/arm64/autobuilds/current-stage3-arm64-openrc/"
NAME=$(curl -s ${ROOT_URL}latest-stage3-arm64-openrc.txt | grep stage3 | awk '{print $1}')
URL=${ROOT_URL}${NAME}
log "downloading tarball"
wget -P $WORK $URL ${URL}.DIGESTS ${URL}.asc
log "contents:"; ls -lh $WORK
confirm "look good?"
TARBALL=${URL##*/}
log "DIGESTS FILE"; cat ${WORK}/${TARBALL}.DIGESTS
log "COMPUTED DIGESTS"; sha512sum ${WORK}/${TARBALL}
confirm "do digests match?"
wget -O - https://qa-reports.gentoo.org/output/service-keys.gpg | gpg --import
gpg --verify ${WORK}/${TARBALL}.asc
log "Gentoo release fingerprint: 13EB BDBE DE7A 1277 5DFD B1BA BB57 2E0E 2D18 2910"
confirm "do fingerprints match?"
tar xpvf ${WORK}/${TARBALL} -C $ROOT/
