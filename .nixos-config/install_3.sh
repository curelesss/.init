#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$SCRIPT_DIR"

USTC="https://mirrors.ustc.edu.cn/nix-channels/store"
TUNA="https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
OFFICIAL="https://cache.nixos.org/"

TOTAL_STEPS=10
CURRENT_STEP=0

# ── Terminal colors ────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Output helpers ─────────────────────────────────────────────────────────────
step() {
  CURRENT_STEP=$((CURRENT_STEP + 1))
  echo ""
  echo -e "${BOLD}${BLUE}┌─────────────────────────────────────────────────────────┐${RESET}"
  echo -e "${BOLD}${BLUE}│  Step ${CURRENT_STEP}/${TOTAL_STEPS} — $1${RESET}"
  echo -e "${BOLD}${BLUE}└─────────────────────────────────────────────────────────┘${RESET}"
}

ok()      { echo -e "  ${GREEN}✓${RESET}  $1"; }
info()    { echo -e "  ${CYAN}→${RESET}  $1"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
abort()   { echo -e "  ${RED}✗${RESET}  $1"; exit 1; }
detail()  { echo -e "  ${DIM}   $1${RESET}"; }
divider() { echo -e "  ${DIM}───────────────────────────────────────────${RESET}"; }

# ── Header ─────────────────────────────────────────────────────────────────────
clear
echo ""
echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}  ║           NixOS Flake Installer                      ║${RESET}"
echo -e "${BOLD}${CYAN}  ║           GRUB (BIOS) · disko · no swap              ║${RESET}"
echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${DIM}What this script does:${RESET}"
detail "1. Collect hostname, disk, and mirror preferences"
detail "2. Enable Nix flakes in the live ISO environment"
detail "3. Copy flake and inject the chosen disk device"
detail "4. Partition and format the disk with disko"
detail "5. Install NixOS from the flake with nixos-install"
echo ""

# ══════════════════════════════════════════════════════════════════════════════
step "Collect installation parameters"
# ══════════════════════════════════════════════════════════════════════════════

# ── Hostname ───────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Hostname${RESET}"
divider
echo -e "  ${DIM}Hosts defined in this flake:${RESET}"
grep 'nixosConfigurations\.' "$FLAKE_DIR/flake.nix" \
  | grep -oP '(?<=nixosConfigurations\.)\w+' \
  | sed "s/^/$(echo -e "  ${CYAN}  •${RESET} ")/"
echo ""
read -rp "  Target hostname [mymachine]: " input_host
HOST="${input_host:-mymachine}"
ok "Hostname → ${BOLD}$HOST${RESET}"

# ── Disk ───────────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Disk device${RESET}"
divider
echo -e "  ${DIM}Detected block devices:${RESET}"
echo ""
lsblk -d -o NAME,SIZE,MODEL,TRAN | grep -v loop | while IFS= read -r line; do
  echo -e "    ${DIM}$line${RESET}"
done
echo ""
read -rp "  Target disk (e.g. /dev/nvme0n1): " DISK

[[ -z "$DISK" ]]   && abort "No disk specified."
[[ ! -b "$DISK" ]] && abort "'$DISK' is not a block device."
ok "Disk → ${BOLD}$DISK${RESET}"

# ── Mirrors ────────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}Binary cache mirrors${RESET}"
divider
detail "Mirrors are tried first, falling back to cache.nixos.org"
echo ""
echo -e "  ${DIM}Available China mirrors:${RESET}"
echo -e "  ${CYAN}  •${RESET} ${DIM}$USTC${RESET}"
echo -e "  ${CYAN}  •${RESET} ${DIM}$TUNA${RESET}"
echo ""
read -rp "  Use China mirrors? [y/N]: " use_mirrors
USE_MIRRORS=false
[[ "${use_mirrors,,}" == "y" || "${use_mirrors,,}" == "yes" ]] && USE_MIRRORS=true

if $USE_MIRRORS; then
  SUBSTITUTERS="$USTC $TUNA $OFFICIAL"
  ok "Mirrors →
