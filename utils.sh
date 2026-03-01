#!/bin/bash

# ===== Colors =====
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ===== Root Check =====
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[!] Please run as root (sudo).${NC}"
        exit 1
    fi
}

# ===== Strict IP Validation =====
validate_ip() {
    local ip=$1
    IFS='.' read -r -a octets <<< "$ip"

    if [[ ${#octets[@]} -ne 4 ]]; then
        return 1
    fi

    for octet in "${octets[@]}"; do
        if ! [[ $octet =~ ^[0-9]+$ ]] || ((octet < 0 || octet > 255)); then
            return 1
        fi
    done

    return 0
}

# ===== Create Required Directories =====
create_directories() {
    mkdir -p logs
    mkdir -p reports
}

# ===== Banner =====
show_banner() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "        AutoReconLite v2.0"
    echo "        Advanced Bash Scanner"
    echo "=========================================="
    echo -e "${NC}"
}
