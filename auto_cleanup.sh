#!/usr/bin/env bash

set -euo pipefail

# Colors
RED=$'\e[31m'
GREEN=$'\e[32m'
YELLOW=$'\e[33m'
CYAN=$'\e[36m'
MAGENTA=$'\e[35m'
RESET=$'\e[0m'

print_header() {
    clear
    echo -e "${CYAN}======================================"
    echo -e "             AUTO CLEANUP TOOL"
    echo -e "======================================${RESET}"
    echo
}

# Require root once (professional way)
require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Please run as root:${RESET} sudo ./auto_cleanup.sh"
        exit 1
    fi
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr="|/-\\"
    while kill -0 "$pid" 2>/dev/null; do
        printf " ${CYAN}[%c]${RESET}  " "$spinstr"
        spinstr=${spinstr#?}${spinstr%"${spinstr#?}"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "      \b\b\b\b\b\b"
}

run_with_spinner() {
    "$@" >/dev/null 2>&1 &
    spinner $!
    wait $!
}

get_free_space_kb() {
    df --output=avail / | tail -1 | tr -d ' '
}

kb_to_gb() {
    awk -v kb="$1" 'BEGIN {printf "%.1f", kb/1024/1024}'
}

cleanup_apt() {
    echo -ne "${YELLOW}Cleaning APT cache...${RESET}"
    run_with_spinner apt clean -y
    echo -e " ${GREEN}✔${RESET}"
}

cleanup_autoremove() {
    echo -ne "${YELLOW}Removing unused packages...${RESET}"
    run_with_spinner apt autoremove -y
    echo -e " ${GREEN}✔${RESET}"
}

cleanup_tmp() {
    echo -ne "${YELLOW}Cleaning /tmp (older than 3 days)...${RESET}"
    run_with_spinner find /tmp -type f -mtime +3 -delete
    echo -e " ${GREEN}✔${RESET}"
}

cleanup_journal() {
    echo -ne "${YELLOW}Cleaning journal logs...${RESET}"
    run_with_spinner journalctl --vacuum-time=7d
    echo -e " ${GREEN}✔${RESET}"
}

cleanup_thumbnails() {
    local thumb="$HOME/.cache/thumbnails"
    if [[ -d "$thumb" ]]; then
        echo -ne "${YELLOW}Cleaning thumbnail cache...${RESET}"
        run_with_spinner rm -rf "$thumb"/*
        echo -e " ${GREEN}✔${RESET}"
    fi
}

animate_summary() {
    local color="$1"
    local text="$2"
    echo -ne "$color"
    for ((i=0; i<${#text}; i++)); do
        printf "%s" "${text:$i:1}"
        sleep 0.02
    done
    echo -e "${RESET}"
}

main() {
    require_root
    print_header

    before_kb=$(get_free_space_kb)
    before_gb=$(kb_to_gb "$before_kb")

    echo -e "${CYAN}Free space before cleanup: ${YELLOW}${before_gb} GB${RESET}"
    echo

    cleanup_apt
    cleanup_autoremove
    cleanup_tmp
    cleanup_journal
    cleanup_thumbnails
    echo

    after_kb=$(get_free_space_kb)
    after_gb=$(kb_to_gb "$after_kb")

    freed_kb=$((after_kb - before_kb))
    ((freed_kb < 0)) && freed_kb=0
    freed_gb=$(kb_to_gb "$freed_kb")

    echo -e "${MAGENTA}======================================${RESET}"
    echo -e "${GREEN}✅ Cleanup Completed Successfully!${RESET}"
    echo

    animate_summary "$CYAN" "Before: $before_gb GB free"
    animate_summary "$CYAN" "After : $after_gb GB free"
    animate_summary "$GREEN" "Freed : $freed_gb GB"

    echo -e "${MAGENTA}======================================${RESET}"
}

main
