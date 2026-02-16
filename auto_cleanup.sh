#!/usr/bin/env bash

set -euo pipefail

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
MAGENTA="\e[35m"
RESET="\e[0m"

print_header() {
    clear
    echo -e "${CYAN}======================================"
    echo -e "             AUTO CLEANUP TOOL"
    echo -e "======================================${RESET}"
    echo
}

get_free_space_kb() {
    df --output=avail / | tail -1 | tr -d ' '
}

cleanup_apt() {
    echo -e "${YELLOW}Cleaning APT cache...${RESET}"
    sudo apt clean -y
}

cleanup_tmp() {
    echo -e "${YELLOW}Cleaning /tmp (files older than 3 days)...${RESET}"
    sudo find /tmp -type f -mtime +3 -delete
}

cleanup_journal() {
    echo -e "${YELLOW}Cleaning journal logs (older than 7 days)...${RESET}"
    sudo journalctl --vacuum-time=7d >/dev/null
}

cleanup_thumbnails() {
    local thumb="$HOME/.cache/thumbnails"
    if [[ -d "$thumb" ]]; then
        echo -e "${YELLOW}Cleaning thumbnail cache...${RESET}"
        rm -rf "$thumb"/*
    fi
}

calculate_freed_space() {
    local before=$1
    local after=$2
    local diff=$((after - before))
    echo $((diff / 1024))
}

main() {
    print_header

    echo -e "${CYAN}Measuring disk space before cleanup...${RESET}"
    before_space=$(get_free_space_kb)

    echo
    cleanup_apt
    cleanup_tmp
    cleanup_journal
    cleanup_thumbnails
    echo

    echo -e "${CYAN}Measuring disk space after cleanup...${RESET}"
    after_space=$(get_free_space_kb)

    freed_mb=$(calculate_freed_space "$before_space" "$after_space")

    echo
    echo -e "${MAGENTA}======================================${RESET}"
    echo -e "${GREEN}✅ Cleanup Completed Successfully!${RESET}"
    echo -e "${CYAN}🧹 Space Freed: ${YELLOW}${freed_mb} MB${RESET}"
    echo -e "${MAGENTA}======================================${RESET}"
}

main
