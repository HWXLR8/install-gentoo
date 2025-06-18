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

function log {
    echo -e "${RED}* ${1}${NC}"
}
