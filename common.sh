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
