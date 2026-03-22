#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$SCRIPT_DIR"

USTC="https://mirrors.ustc.edu.cn/nix-channels/store"
TUNA="https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
OFFICIAL="https://cache.nixos.org/"

TOTAL_STEPS=10
CURRENT_STEP=0

step() {
  CURRENT_STEP=$((CURRENT_STEP + 1))
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  [${CURRENT_STEP}/${TOTAL_STEPS}] $1"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

ok()   { echo "  [ok] $1"; }
info() { echo "  [..] $1"; }
warn() { echo "  [!!] $1"; }

# ── Header ─────────────────────────────────────────────────────────────────────
clear
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║           NixOS Flake Installer                      ║"
echo "║           GRUB (BIOS) + disko, no swap               ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "  This script will:"
echo "  1. Ask for hostname, disk, and mirror preference"
echo "  2. Partition and format the target disk with disko"
echo "  3. Install NixOS from your local flake"
echo ""

# ══════════════════════════════════════════════════════════════════════════════
step "Collect installation parameters"
# ══════════════════════════════════════════════════════════════════════════════

# Hostname
echo ""
echo "  Hosts defined in this flake:"
grep 'nixosConfigurations\.' "$FLAKE_DIR/flake.nix" \
  | grep -oP '(?<=nixosConfigurations\.)\w+' \
  | sed 's/^/    /'
echo ""
read -rp "  Hostname to install [mymachine]: " input_host
HOST="${input_host:-mymachine}"
ok "Hostname set to: $HOST"

# Disk
echo ""
echo "  Available block devices:"
echo "  ────────────────────────────────────────────────────"
lsblk -d -o NAME,SIZE,MODEL,TRAN | grep -v loop | sed 's/^/  /'
echo "  ────────────────────────────────────────────────────"
echo ""
read -rp "  Target disk device (e.g. /dev/nvme0n1): " DISK

[[ -z "$DISK" ]]   && { warn "No disk specified. Aborting.";           exit 1; }
[[ ! -b "$DISK" ]] && { warn "'$DISK' is not a block device. Aborting."; exit 1; }
ok "Target disk set to: $DISK"

# China mirrors
echo ""
echo "  Binary cache mirrors available:"
echo "    1) $USTC"
echo "    2) $TUNA"
echo "  (both will be tried before falling back to cache.nixos.org)"
echo ""
read -rp "  Use China mirrors? [y/N]: " use_mirrors
USE_MIRRORS=false
[[ "${use_mirrors,,}" == "y" || "${use_mirrors,,}" == "yes" ]] && USE_MIRRORS=true

if $USE_MIRRORS; then
  SUBSTITUTERS="$USTC $TUNA $OFFICIAL"
  ok "China mirrors enabled"
else
  SUBSTITUTERS="$OFFICIAL"
  ok "Using official cache.nixos.org only"
fi

# ══════════════════════════════════════════════════════════════════════════════
step "Confirm installation — point of no return"
# ══════════════════════════════════════════════════════════════════════════════

echo ""
echo "  ┌─────────────────────────────────────────────────┐"
echo "  │  Flake   : $FLAKE_DIR"
echo "  │  Host    : $HOST"
echo "  │  Disk    : $DISK"
echo "  │  Mirrors : $USE_MIRRORS"
echo "  └─────────────────────────────────────────────────┘"
echo ""
echo "  !! ALL DATA ON $DISK WILL BE PERMANENTLY ERASED !!"
echo ""
read -rp "  Type YES to continue: " confirm
[[ "$confirm" != "YES" ]] && { echo "  Aborted."; exit 1; }
ok "Confirmed — proceeding with installation"

# ══════════════════════════════════════════════════════════════════════════════
step "Enable Nix flakes for user and root"
# ══════════════════════════════════════════════════════════════════════════════
# /etc/nix is read-only in the live ISO.
# We write nix.conf to both ~/.config/nix/ (current user) and
# /root/.config/nix/ (sudo commands) so all nix invocations see the same
# config. NIX_CONFIG env var covers the current shell session immediately.

NIX_CONF="experimental-features = nix-command flakes
substituters = $SUBSTITUTERS
trusted-substituters = $SUBSTITUTERS
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="

mkdir -p ~/.config/nix
echo "$NIX_CONF" > ~/.config/nix/nix.conf
ok "Written ~/.config/nix/nix.conf"

sudo mkdir -p /root/.config/nix
echo "$NIX_CONF" | sudo tee /root/.config/nix/nix.conf > /dev/null
ok "Written /root/.config/nix/nix.conf"

export NIX_CONFIG="$NIX_CONF"
ok "NIX_CONFIG exported for current shell session"

# ══════════════════════════════════════════════════════════════════════════════
step "Prepare flake copy with disk device injected"
# ══════════════════════════════════════════════════════════════════════════════
# We copy the entire flake to /tmp and inject a disk-override.nix module that
# sets myConfig.diskDevice to the user's chosen disk. This avoids the narHash
# assertion error caused by the extendModules wrapper flake approach — the
# copied flake retains the same flake.lock so all hashes stay consistent.

WORKDIR=$(mktemp -d /tmp/nixos-install-XXXXXX)
trap 'rm -rf "$WORKDIR"' EXIT

info "Copying flake to $WORKDIR"
cp -r "$FLAKE_DIR/." "$WORKDIR/"
ok "Flake copied"

DISKO_FILE="$WORKDIR/hosts/$HOST/disko.nix"
if [[ ! -f "$DISKO_FILE" ]]; then
  warn "Expected disko file not found: $DISKO_FILE"
  exit 1
fi

# Write the override module
cat > "$WORKDIR/disk-override.nix" <<EOF
{ ... }: {
  myConfig.diskDevice = "$DISK";
}
EOF

# Patch flake.nix in the copy to import the override module
sed -i "s|./hosts/$HOST/disko.nix|./hosts/$HOST/disko.nix\n        ./disk-override.nix|" \
  "$WORKDIR/flake.nix"

ok "Disk device '$DISK' injected via disk-override.nix"

# ══════════════════════════════════════════════════════════════════════════════
step "Read pinned disko revision from flake.lock"
# ══════════════════════════════════════════════════════════════════════════════
# We extract the exact disko commit hash already pinned in flake.lock and pass
# it directly to `nix run github:nix-community/disko/<rev>` — this avoids any
# GitHub API call to resolve 'latest' which hits rate limits quickly.

DISKO_REV=$(awk '/"disko"/{found=1} found && /"rev"/{
  match($0, /"rev": "([^"]+)"/, a); print a[1]; exit}' \
  "$WORKDIR/flake.lock")

if [[ -z "$DISKO_REV" || "$DISKO_REV" == "null" ]]; then
  warn "Could not read disko revision from flake.lock"
  warn "Run: nix flake lock --extra-experimental-features 'nix-command flakes'"
  exit 1
fi
ok "Disko revision: $DISKO_REV"

# ══════════════════════════════════════════════════════════════════════════════
step "Partition and format disk with disko"
# ══════════════════════════════════════════════════════════════════════════════
# Disko reads the partition layout from hosts/$HOST/disko.nix and:
#   - Wipes the target disk
#   - Creates a GPT partition table
#   - Creates a 1M EF02 BIOS boot partition (required for GRUB on GPT)
#   - Creates an ext4 root partition using the remaining space
#   - Mounts root to /mnt
# No UUIDs are handled manually — disko resolves them internally.

info "Running disko on $DISK (this will erase all data)"
sudo nix run \
  --extra-experimental-features "nix-command flakes" \
  --substituters "$SUBSTITUTERS" \
  --trusted-substituters "$SUBSTITUTERS" \
  --trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" \
  "github:nix-community/disko/$DISKO_REV" -- \
  --mode disko \
  --flake "$WORKDIR#$HOST"

ok "/mnt is mounted and ready"

# ══════════════════════════════════════════════════════════════════════════════
step "Write nix.conf to /mnt/etc/nix"
# ══════════════════════════════════════════════════════════════════════════════
# nixos-install chroots into /mnt and reads /mnt/etc/nix/nix.conf as its
# nix configuration. Writing the substituters here is the only reliable way
# to make the entire nixos-install build use the China mirrors — passing
# --option flags on the command line is overridden by the chroot environment.

sudo mkdir -p /mnt/etc/nix
echo "$NIX_CONF" | sudo tee /mnt/etc/nix/nix.conf > /dev/null
ok "Mirror config written to /mnt/etc/nix/nix.conf"

# ══════════════════════════════════════════════════════════════════════════════
step "Copy password hash file to /mnt"
# ══════════════════════════════════════════════════════════════════════════════
# The hashedPasswordFile option in default.nix points to /etc/nixos/fdong.hash
# on the installed system. We copy it into /mnt/etc/nixos/ now so it exists
# when nixos-install activates the system configuration.
# Generate the hash with: mkpasswd -m sha-512 'yourpassword'

HASH_FILE="$FLAKE_DIR/hosts/$HOST/fdong.hash"
if [[ -f "$HASH_FILE" ]]; then
  sudo mkdir -p /mnt/etc/nixos
  sudo cp "$HASH_FILE" /mnt/etc/nixos/fdong.hash
  sudo chmod 600 /mnt/etc/nixos/fdong.hash
  ok "Password hash copied to /mnt/etc/nixos/fdong.hash"
else
  warn "Hash file not found at $HASH_FILE"
  warn "User fdong will have no password — you will need to set it manually after boot"
fi

# ══════════════════════════════════════════════════════════════════════════════
step "Install NixOS from flake"
# ══════════════════════════════════════════════════════════════════════════════
# nixos-install builds the system closure defined in the flake, copies it to
# /mnt/nix/store, writes /mnt/etc/nixos, and installs the GRUB bootloader.
# --no-root-passwd skips setting a root password (we use a user account).
# This step downloads the bulk of the system — expect several hundred MB.

info "Starting nixos-install — this will take a while"
sudo nixos-install \
  --no-root-passwd \
  --flake "$WORKDIR#$HOST"

# ══════════════════════════════════════════════════════════════════════════════
step "Installation complete"
# ══════════════════════════════════════════════════════════════════════════════

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   Installation complete!                             ║"
echo "║                                                      ║"
echo "║   Next steps:                                        ║"
echo "║   1. sudo reboot                                     ║"
echo "║   2. Log in as fdong with your password              ║"
echo "║   3. Clone your repo:                                ║"
echo "║      mkdir -p ~/.init                                ║"
echo "║      git clone <your-repo-url> ~/.init/.nixos-config ║"
echo "║   4. Future rebuilds:                                ║"
echo "║      cd ~/.init/.nixos-config                        ║"
echo "║      sudo nixos-rebuild switch --flake .#$HOST       ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
