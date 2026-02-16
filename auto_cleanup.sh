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

kb_to_gb() {
    awk "BEGIN {printf \"%.1f\", $1/1024/1024}"
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

main() {
    print_header

    before_kb=$(get_free_space_kb)
    before_gb=$(kb_to_gb "$before_kb")

    echo -e "${CYAN}Free space before cleanup: ${YELLOW}${before_gb} GB${RESET}"
    echo

    cleanup_apt
    cleanup_tmp
    cleanup_journal
    cleanup_thumbnails
    echo

    after_kb=$(get_free_space_kb)
    after_gb=$(kb_to_gb "$after_kb")

    freed_kb=$((after_kb - before_kb))
    freed_gb=$(kb_to_gb "$freed_kb")

    echo -e "${MAGENTA}======================================${RESET}"
    echo -e "${GREEN}✅ Cleanup Completed Successfully!${RESET}"
    echo
    echo -e "${CYAN}Before: ${YELLOW}${before_gb} GB free${RESET}"
    echo -e "${CYAN}After : ${YELLOW}${after_gb} GB free${RESET}"
    echo -e "${CYAN}Freed : ${GREEN}${freed_gb} GB${RESET}"
    echo -e "${MAGENTA}======================================${RESET}"
}

main
