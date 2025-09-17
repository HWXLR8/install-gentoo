# colors
RED='\033[0;31m'
NC='\033[0m'

confirm() {
    read -p "$1 [Y/n] " -r
    if [[ ! $REPLY =~ ^([Yy]|)$ ]]; then
        echo "quitting"
        exit
    fi
}

log() {
    echo -e "${RED}* ${1}${NC}"
}

check_if_root() {
    # check if user is root
    if [ "$EUID" -ne 0 ]; then
        echo "please run as root"
        exit
    fi
}

gentoo_chroot() {
    log "copying files into chroot"
    cp -v ../post-chroot.sh .
    cp -v ../common.sh .
    cp -v /etc/resolv.conf etc
    log "begin chroot"
    mount -t proc none proc
    mount --rbind /sys sys
    mount --make-rslave sys
    mount --rbind /dev dev
    mount --make-rslave dev
    chroot . /bin/bash
}

sync_portage() {
    log "SYNCING PORTAGE TREE"
    emerge-webrsync
}

user_setup() {
    log "SET ROOT PASSWORD"
    passwd
    log "CREATING UNPRIVLEGED USER"
    read -p "Enter unprivleged username: " USERNAME
    useradd -g users -G wheel,portage,audio,video,usb,cdrom -m $USERNAME
    log "SET UNPRIVLEGED USER PASSWORD"
    passwd $USERNAME
}

locale_setup() {
    log "SETTING LOCALE"
    echo 'LANG="en_US.UTF-8"' > /etc/env.d/02locale
    echo 'LC_COLLATE="C"' >> /etc/env.d/02locale
    echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen
    echo 'C.UTF8 UTF-8' >> /etc/locale.gen
    log "GENERATING LOCALE"
    locale-gen
}

hostname_setup() {
    log "SET HOST NAME"
    read -p "Enter hostname: " HOST
    echo "$HOST" > /etc/hostname
}

timezone_setup() {
    log "SETTING TIMEZONE"
    ln -sf /usr/share/zoneinfo/Canada/Eastern /etc/localtime
}

tmpfs_setup() {
    log "SETTING TMPFS for /tmp"
    echo "tmpfs                    /tmp           tmpfs    defaults,noatime,nosuid,nodev,mode=1777,size=10240M 0 0" >> /etc/fstab
}

ntp_setup() {
    log "emerging ntp"
    emerge net-misc/ntp
    log "adding ntp-client to default runlevel"
    rc-update add ntp-client default
}

sudo_setup() {
    log "emerging sudo"
    USE="-sendmail" emerge sudo
    log "modifying /etc/sudoers"
    sed -i '/%wheel ALL=(ALL:ALL) ALL/ s/^[[:space:]]*#[[:space:]]*//' /etc/sudoers
}
