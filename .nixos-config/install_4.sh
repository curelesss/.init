#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$SCRIPT_DIR"

USTC="https://mirrors.ustc.edu.cn/nix-channels/store"
TUNA="https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
OFFICIAL="https://cache.nixos.org/"
PUBKEY="cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="

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
label()   { echo -e "\n  ${BOLD}$1${RESET}"; divider; }

# ── Header ─────────────────────────────────────────────────────────────────────
clear
echo ""
echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}  ║           NixOS Flake Installer                      ║${RESET}"
echo -e "${BOLD}${CYAN}  ║           disko · no swap                            ║${RESET}"
echo -e "${BOLD}${CYAN}  ║           x86_64: GRUB BIOS                          ║${RESET}"
echo -e "${BOLD}${CYAN}  ║           aarch64: systemd-boot UEFI                 ║${RESET}"
echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${DIM}What this script does:${RESET}"
detail "1. Detect architecture and collect install parameters"
detail "2. Enable Nix flakes in the live ISO environment"
detail "3. Copy flake and inject the chosen disk device"
detail "4. Partition and format the disk with disko"
detail "5. Install NixOS from the flake with nixos-install"
echo ""

# ══════════════════════════════════════════════════════════════════════════════
step "Detect architecture"
# ══════════════════════════════════════════════════════════════════════════════
# Detect whether we are running on x86_64 or aarch64 so we can inform the
# user which bootloader will be used. The actual bootloader choice is defined
# in each host's default.nix — this is for display purposes only.

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)
    ARCH_LABEL="x86_64 — GRUB BIOS mode"
    ;;
  aarch64)
    ARCH_LABEL="aarch64 — systemd-boot UEFI mode (Apple Silicon / ARM)"
    ;;
  *)
    ARCH_LABEL="$ARCH — unknown, proceeding anyway"
    ;;
esac

ok "Architecture detected → ${BOLD}$ARCH_LABEL${RESET}"

# ══════════════════════════════════════════════════════════════════════════════
step "Collect installation parameters"
# ══════════════════════════════════════════════════════════════════════════════

# # ── Hostname ───────────────────────────────────────────────────────────────────
# label "Hostname"
# echo -e "  ${DIM}Hosts defined in this flake:${RESET}"
# grep 'nixosConfigurations\.' "$FLAKE_DIR/flake.nix" \
#   | grep -oP '(?<=nixosConfigurations\.)\w+' \
#   | while IFS= read -r h; do
#       echo -e "  ${CYAN}  •${RESET} ${DIM}$h${RESET}"
#     done
# echo ""

# ── Hostname ───────────────────────────────────────────────────────────────────
label "Hostname"
echo -e "  ${DIM}Hosts defined in this flake:${RESET}"

# Use || true to prevent grep/pipeline failure from triggering set -e exit
grep 'nixosConfigurations\.' "$FLAKE_DIR/flake.nix" \
  | grep -oP '(?<=nixosConfigurations\.)\w+' \
  | while IFS= read -r h; do
      echo -e "  ${CYAN}  •${RESET} ${DIM}$h${RESET}"
    done || true

echo ""

# Suggest default based on arch
if [[ "$ARCH" == "aarch64" ]]; then
  DEFAULT_HOST="nixos-arm"
else
  DEFAULT_HOST="mymachine"
fi

read -rp "  Target hostname [$DEFAULT_HOST]: " input_host
HOST="${input_host:-$DEFAULT_HOST}"
ok "Hostname → ${BOLD}$HOST${RESET}"

# ── Disk ───────────────────────────────────────────────────────────────────────
label "Disk device"
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
label "Binary cache mirrors"
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
  ok "Mirrors → ${BOLD}China + official${RESET}"
else
  SUBSTITUTERS="$OFFICIAL"
  ok "Mirrors → ${BOLD}official cache.nixos.org only${RESET}"
fi

# ── Build NIX_CONF now that SUBSTITUTERS is known ─────────────────────────────
# PUBKEY is defined at the top of the script to avoid inline = signs inside
# double-quoted multi-line strings which confuse bash string parsing.
NIX_CONF="experimental-features = nix-command flakes
substituters = $SUBSTITUTERS
trusted-substituters = $SUBSTITUTERS
trusted-public-keys = $PUBKEY"

# ══════════════════════════════════════════════════════════════════════════════
step "Confirm — point of no return"
# ══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "  ${BOLD}Installation summary${RESET}"
divider
echo -e "  ${DIM}Flake path    :${RESET} $FLAKE_DIR"
echo -e "  ${DIM}Host          :${RESET} ${BOLD}$HOST${RESET}"
echo -e "  ${DIM}Disk          :${RESET} ${BOLD}$DISK${RESET}"
echo -e "  ${DIM}Architecture  :${RESET} $ARCH"
echo -e "  ${DIM}Mirrors       :${RESET} $USE_MIRRORS"
echo ""
echo -e "  ${RED}${BOLD}  !! ALL DATA ON $DISK WILL BE PERMANENTLY ERASED !!${RESET}"
echo ""
read -rp "  Type YES to continue: " confirm
[[ "$confirm" != "YES" ]] && { echo -e "\n  ${YELLOW}Aborted.${RESET}\n"; exit 1; }
ok "Confirmed — installation will begin"

# ══════════════════════════════════════════════════════════════════════════════
step "Enable Nix flakes for user and root"
# ══════════════════════════════════════════════════════════════════════════════
# /etc/nix is read-only in the live ISO. We write nix.conf to both the
# current user config and root config so all `sudo nix` calls see the same
# substituters and experimental features. NIX_CONFIG env var covers the
# current shell session immediately without needing a daemon restart.

mkdir -p ~/.config/nix
echo "$NIX_CONF" > ~/.config/nix/nix.conf
ok "~/.config/nix/nix.conf written"

sudo mkdir -p /root/.config/nix
echo "$NIX_CONF" | sudo tee /root/.config/nix/nix.conf > /dev/null
ok "/root/.config/nix/nix.conf written"

export NIX_CONFIG="$NIX_CONF"
ok "NIX_CONFIG exported to current shell"

# ══════════════════════════════════════════════════════════════════════════════
step "Prepare flake copy with disk device injected"
# ══════════════════════════════════════════════════════════════════════════════
# We copy the entire flake to /tmp and add a disk-override.nix module that
# sets myConfig.diskDevice to the user's chosen disk. This avoids the narHash
# assertion error caused by the extendModules wrapper flake approach — the
# copied flake retains the same flake.lock so all content hashes stay
# consistent and nixos-install never complains about hash mismatches.

WORKDIR=$(mktemp -d /tmp/nixos-install-XXXXXX)
trap 'rm -rf "$WORKDIR"' EXIT

info "Copying flake to $WORKDIR"
cp -r "$FLAKE_DIR/." "$WORKDIR/"
ok "Flake copied to temp directory"

DISKO_FILE="$WORKDIR/hosts/$HOST/disko.nix"
[[ ! -f "$DISKO_FILE" ]] && abort "disko.nix not found at $DISKO_FILE"

# Write the override module that injects the disk device at evaluation time
cat > "$WORKDIR/disk-override.nix" <<EOF
{ ... }: {
  myConfig.diskDevice = "$DISK";
}
EOF

# Patch flake.nix in the copy to import disk-override.nix alongside disko.nix
sed -i \
  "s|./hosts/$HOST/disko.nix|./hosts/$HOST/disko.nix\n        ./disk-override.nix|" \
  "$WORKDIR/flake.nix"

ok "disk-override.nix written → myConfig.diskDevice = \"$DISK\""

# ══════════════════════════════════════════════════════════════════════════════
step "Read pinned disko revision from flake.lock"
# ══════════════════════════════════════════════════════════════════════════════
# We extract the exact disko commit hash already pinned in flake.lock and pass
# it directly to `nix run github:nix-community/disko/<rev>`. This bypasses the
# GitHub API HEAD lookup that triggers rate limiting (60 req/hr unauthenticated)
# — fetching a specific commit hash uses the tarball CDN directly.

DISKO_REV=$(awk '/"disko"/{found=1} found && /"rev"/{
  match($0, /"rev": "([^"]+)"/, a); print a[1]; exit}' \
  "$WORKDIR/flake.lock")

if [[ -z "$DISKO_REV" || "$DISKO_REV" == "null" ]]; then
  warn "Could not read disko revision from flake.lock"
  abort "Run: nix flake lock --extra-experimental-features 'nix-command flakes'"
fi
ok "Disko revision → ${BOLD}${DISKO_REV:0:16}...${RESET}"

# ══════════════════════════════════════════════════════════════════════════════
step "Partition and format disk with disko"
# ══════════════════════════════════════════════════════════════════════════════
# Disko reads hosts/$HOST/disko.nix and performs:
#
#   x86_64 host (nixos):
#     • Partition 1: 1M   EF02 — BIOS boot partition (GRUB on GPT)
#     • Partition 2: rest 8300 — ext4 root → /
#
#   aarch64 host (nixos-arm):
#     • Partition 1: 512M EF00 — ESP vfat → /boot (systemd-boot UEFI)
#     • Partition 2: rest 8300 — ext4 root → /
#
# UUID references are resolved internally by disko — no manual UUID handling.
# The --substituters flag is passed directly to `nix run` because sudo drops
# the NIX_CONFIG env var when spawning a new process.

echo ""
warn "Wiping and repartitioning $DISK — this is irreversible"
echo ""

sudo nix run \
  --extra-experimental-features "nix-command flakes" \
  --substituters "$SUBSTITUTERS" \
  --trusted-substituters "$SUBSTITUTERS" \
  --trusted-public-keys "$PUBKEY" \
  "github:nix-community/disko/$DISKO_REV" -- \
  --mode disko \
  --flake "$WORKDIR#$HOST"

echo ""
ok "Disk partitioned and formatted"
ok "/mnt mounted and ready"

# ══════════════════════════════════════════════════════════════════════════════
step "Write nix.conf to target system"
# ══════════════════════════════════════════════════════════════════════════════
# nixos-install chroots into /mnt and reads /mnt/etc/nix/nix.conf as its nix
# configuration. Writing substituters here before calling nixos-install is the
# only reliable way to make the entire build use the mirror caches — passing
# --option flags on the nixos-install CLI is overridden once the chroot starts.

sudo mkdir -p /mnt/etc/nix
echo "$NIX_CONF" | sudo tee /mnt/etc/nix/nix.conf > /dev/null
ok "/mnt/etc/nix/nix.conf written"
if $USE_MIRRORS; then
  detail "Substituters: USTC → TUNA → cache.nixos.org"
else
  detail "Substituters: cache.nixos.org"
fi

# ══════════════════════════════════════════════════════════════════════════════
step "Copy password hash file to target system"
# ══════════════════════════════════════════════════════════════════════════════
# default.nix sets hashedPasswordFile = "/etc/nixos/fdong.hash". The file must
# exist on the installed system at first activation or the user will have no
# password. We look for a host-specific hash first, then fall back to the
# repo root. Generate with: mkpasswd -m sha-512 'yourpassword'

HASH_FILE="$FLAKE_DIR/hosts/$HOST/fdong.hash"
[[ ! -f "$HASH_FILE" ]] && HASH_FILE="$FLAKE_DIR/fdong.hash"

if [[ -f "$HASH_FILE" ]]; then
  sudo mkdir -p /mnt/etc/nixos
  sudo cp "$HASH_FILE" /mnt/etc/nixos/fdong.hash
  sudo chmod 600 /mnt/etc/nixos/fdong.hash
  ok "/mnt/etc/nixos/fdong.hash copied (mode 600)"
  detail "Source: $HASH_FILE"
else
  warn "Hash file not found at hosts/$HOST/fdong.hash or repo root"
  warn "User fdong will have no password — set it after boot with: passwd fdong"
fi

# ══════════════════════════════════════════════════════════════════════════════
step "Install NixOS from flake"
# ══════════════════════════════════════════════════════════════════════════════
# nixos-install performs the following:
#   • Evaluates the flake's nixosConfigurations.$HOST
#   • Builds the full system closure and copies it to /mnt/nix/store
#   • Writes system configuration files to /mnt/etc
#   • x86_64: Installs GRUB bootloader to $DISK (BIOS/i386-pc mode)
#   • aarch64: Installs systemd-boot to /mnt/boot (UEFI ESP)
#   • Does NOT set a root password (--no-root-passwd)
# This step downloads the bulk of the system — typically 300–800 MiB.
# Download size depends heavily on cache hit rate from the chosen mirrors.

echo ""
info "Building system closure and downloading packages..."
detail "This is the longest step — download size depends on cache hit rate"
echo ""

sudo nixos-install \
  --no-root-passwd \
  --flake "$WORKDIR#$HOST"

# ══════════════════════════════════════════════════════════════════════════════
step "Installation complete"
# ══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}${GREEN}  ╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}  ║   ✓  Installation complete!                          ║${RESET}"
echo -e "${BOLD}${GREEN}  ╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${BOLD}Next steps:${RESET}"
echo ""
echo -e "  ${CYAN}1.${RESET} Reboot into your new system:"
echo -e "     ${DIM}sudo reboot${RESET}"
echo ""
echo -e "  ${CYAN}2.${RESET} Log in as fdong with your password"
echo ""
echo -e "  ${CYAN}3.${RESET} Clone your config repo:"
echo -e "     ${DIM}mkdir -p ~/.init${RESET}"
echo -e "     ${DIM}git clone <your-repo-url> ~/.init/.nixos-config${RESET}"
echo ""
echo -e "  ${CYAN}4.${RESET} Future rebuilds:"
echo -e "     ${DIM}cd ~/.init/.nixos-config${RESET}"
echo -e "     ${DIM}sudo nixos-rebuild switch --flake .#${HOST}${RESET}"
echo ""
echo -e "  ${CYAN}5.${RESET} Update flake inputs:"
echo -e "     ${DIM}nix flake update${RESET}"
echo -e "     ${DIM}git add flake.lock && git commit -m 'bump inputs' && git push${RESET}"
echo ""
