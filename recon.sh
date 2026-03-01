#!/bin/bash

source utils.sh

check_root
show_banner

TARGET=""
MODE="quick"
VULN_SCAN=false

usage() {
    echo "Usage: sudo ./recon.sh -t <target_ip> [-m quick|full] [-v]"
    echo
    echo "Options:"
    echo "  -t    Target IP address"
    echo "  -m    Scan mode (quick or full)"
    echo "  -v    Enable vulnerability scan"
    echo "  -h    Show help menu"
    exit 1
}

while getopts "t:m:vh" opt; do
    case $opt in
        t) TARGET=$OPTARG ;;
        m) MODE=$OPTARG ;;
        v) VULN_SCAN=true ;;
        h) usage ;;
        *) usage ;;
    esac
done

if [[ -z "$TARGET" ]]; then
    usage
fi

validate_ip $TARGET
if [[ $? -ne 0 ]]; then
    echo -e "${RED}[!] Invalid IP address.${NC}"
    exit 1
fi

create_directories

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REPORT="reports/${TARGET}_${TIMESTAMP}.txt"
VULN_REPORT="reports/${TARGET}_vuln_${TIMESTAMP}.txt"

echo -e "${GREEN}[+] Target: $TARGET${NC}"
echo -e "${GREEN}[+] Mode: $MODE${NC}"
echo -e "${GREEN}[+] Vulnerability Scan: $VULN_SCAN${NC}"
echo

# ===== QUICK MODE =====
if [[ "$MODE" == "quick" ]]; then
    echo -e "${YELLOW}[1] Running Quick SYN Scan...${NC}"
    nmap -sS $TARGET > logs/syn_scan.log
fi

# ===== FULL MODE =====
if [[ "$MODE" == "full" ]]; then
    echo -e "${YELLOW}[1] Running Full TCP Scan...${NC}"
    nmap -sS $TARGET > logs/syn_scan.log &

    echo -e "${YELLOW}[2] Running Service Detection...${NC}"
    nmap -sV $TARGET > logs/service_scan.log &

    echo -e "${YELLOW}[3] Running OS Detection...${NC}"
    nmap -O $TARGET > logs/os_scan.log &

    wait
fi

# ===== Extract Open Ports =====
echo -e "${YELLOW}[+] Extracting Open Ports...${NC}"

if [[ -f logs/service_scan.log ]]; then
    grep "open" logs/service_scan.log > "$REPORT"
else
    grep "open" logs/syn_scan.log > "$REPORT"
fi

# ===== Vulnerability Scan =====
if [[ "$VULN_SCAN" == true ]]; then
    echo -e "${YELLOW}[4] Running Vulnerability Scan (nmap --script vuln)...${NC}"
    nmap --script vuln $TARGET > "$VULN_REPORT"
fi

# ===== Add Pentest Summary =====
{
    echo
    echo "=========================================="
    echo "        Pentest Summary Report"
    echo "=========================================="
    echo "Target: $TARGET"
    echo "Mode: $MODE"
    echo "Vulnerability Scan: $VULN_SCAN"
    echo "Scan Date: $TIMESTAMP"
    echo "=========================================="
} >> "$REPORT"

echo
echo -e "${GREEN}[✓] Recon Completed Successfully!${NC}"
echo -e "${GREEN}[✓] Main Report: $REPORT${NC}"

if [[ "$VULN_SCAN" == true ]]; then
    echo -e "${GREEN}[✓] Vulnerability Report: $VULN_REPORT${NC}"
fi
