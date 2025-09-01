#!/bin/bash

set -euo pipefail

source ../common.sh
source ./config.sh

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
mkdir -pv $ROOT/var/db/repos/gentoo
tar xpvf "$SNAPSHOT" --strip-components=1 -C $ROOT/var/db/repos/gentoo
