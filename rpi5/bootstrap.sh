#!/bin/bash

set -euo pipefail

function log {
    RED='\033[0;31m'
    NC='\033[0m'
    echo -e "${RED}* ${1}${NC}"
}
