#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$SCRIPT_DIR"

USTC="https://mirrors.ustc.edu.cn/nix-channels/store"
TUNA="https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
OFFICIAL="https://cache.nixos.org/"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║       NixOS Flake Installer          ║"
echo "║       GRUB + disko, no swap          ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── 1. Hostname ────────────────────────────────────────────────────────────────
echo "Hosts defined in this flake:"
grep 'nixosConfigurations\.' "$FLAKE_DIR/flake.nix" \
  | grep -oP '(?<=nixosConfigurations\.)\w+' \
  | sed 's/^/  /'
echo ""
read -rp "Hostname to install [mymachine]: " input_host
HOST="${input_host:-mymachine}"

# ── 2. Disk ────────────────────────────────────────────────────────────────────
echo ""
echo "Available block devices:"
echo "──────────────────────────────────────────────────────"
lsblk -d -o NAME,SIZE,MODEL,TRAN | grep -v loop
echo "──────────────────────────────────────────────────────"
echo ""
read -rp "Target disk device (e.g. /dev/nvme0n1): " DISK

[[ -z "$DISK" ]]   && { echo "Error: no disk specified.";             exit 1; }
[[ ! -b "$DISK" ]] && { echo "Error: '$DISK' is not a block device."; exit 1; }

# ── 3. China mirrors ──────────────────────────────────────────────────────────
echo ""
echo "Binary cache mirrors:"
echo "  $USTC"
echo "  $TUNA"
echo ""
read -rp "Use China mirrors? [y/N]: " use_mirrors
USE_MIRRORS=false
[[ "${use_mirrors,,}" == "y" || "${use_mirrors,,}" == "yes" ]] && USE_MIRRORS=true

if $USE_MIRRORS; then
  SUBSTITUTERS="$USTC $TUNA $OFFICIAL"
  echo "[ok] China mirrors will be used"
else
  SUBSTITUTERS="$OFFICIAL"
  echo "[ok] using default cache.nixos.org only"
fi

# ── 4. Confirm ─────────────────────────────────────────────────────────────────
echo ""
echo "  Flake   : $FLAKE_DIR"
echo "  Host    : $HOST"
echo "  Disk    : $DISK"
echo "  Mirrors : $USE_MIRRORS"
echo ""
echo "  !! ALL DATA ON $DISK WILL BE PERMANENTLY ERASED !!"
echo ""
read -rp "  Type YES to continue: " confirm
[[ "$confirm" != "YES" ]] && { echo "Aborted."; exit 1; }

# ── 5. Enable flakes + write nix config for user and root ─────────────────────
NIX_CONF="experimental-features = nix-command flakes
substituters = $SUBSTITUTERS
trusted-substituters = $SUBSTITUTERS
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="

mkdir -p ~/.config/nix
echo "$NIX_CONF" > ~/.config/nix/nix.conf

sudo mkdir -p /root/.config/nix
echo "$NIX_CONF" | sudo tee /root/.config/nix/nix.conf > /dev/null

export NIX_CONFIG="$NIX_CONF"
echo "[ok] nix config written (user + root)"

# ── 6. Copy flake and inject disk device ──────────────────────────────────────
WORKDIR=$(mktemp -d /tmp/nixos-install-XXXXXX)
trap 'rm -rf "$WORKDIR"' EXIT

echo "[..] copying flake to $WORKDIR"
cp -r "$FLAKE_DIR/." "$WORKDIR/"

DISKO_FILE="$WORKDIR/hosts/$HOST/disko.nix"
if [[ ! -f "$DISKO_FILE" ]]; then
  echo "Error: $DISKO_FILE not found."
  exit 1
fi

cat > "$WORKDIR/disk-override.nix" <<EOF
{ ... }: {
  myConfig.diskDevice = "$DISK";
}
EOF

sed -i "s|./hosts/$HOST/disko.nix|./hosts/$HOST/disko.nix\n        ./disk-override.nix|" \
  "$WORKDIR/flake.nix"

echo "[ok] disk device '$DISK' injected into flake copy"

# ── 7. Read disko revision from flake.lock ────────────────────────────────────
DISKO_REV=$(awk '/"disko"/{found=1} found && /"rev"/{
  match($0, /"rev": "([^"]+)"/, a); print a[1]; exit}' \
  "$WORKDIR/flake.lock")

if [[ -z "$DISKO_REV" || "$DISKO_REV" == "null" ]]; then
  echo "Error: could not read disko revision from flake.lock"
  exit 1
fi
echo "[ok] disko revision: $DISKO_REV"

# ── 8. Disko: partition, format, mount ────────────────────────────────────────
echo ""
echo "[..] disko — partitioning $DISK"

sudo nix run \
  --extra-experimental-features "nix-command flakes" \
  --substituters "$SUBSTITUTERS" \
  --trusted-substituters "$SUBSTITUTERS" \
  --trusted-public-keys "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" \
  "github:nix-community/disko/$DISKO_REV" -- \
  --mode disko \
  --flake "$WORKDIR#$HOST"

echo "[ok] /mnt mounted"

# ── 9. Write nix.conf to /mnt so nixos-install uses the same mirrors ──────────
sudo mkdir -p /mnt/etc/nix
echo "$NIX_CONF" | sudo tee /mnt/etc/nix/nix.conf > /dev/null
echo "[ok] nix config written to /mnt/etc/nix/nix.conf"

# ── 10. Copy password hash file if present ────────────────────────────────────
HASH_FILE="$FLAKE_DIR/hosts/$HOST/fdong.hash"
if [[ -f "$HASH_FILE" ]]; then
  sudo mkdir -p /mnt/etc/nixos
  sudo cp "$HASH_FILE" /mnt/etc/nixos/fdong.hash
  sudo chmod 600 /mnt/etc/nixos/fdong.hash
  echo "[ok] password hash file copied to /mnt/etc/nixos/fdong.hash"
else
  echo "[warn] no hash file found at $HASH_FILE — user will have no password"
fi

# ── 11. nixos-install ─────────────────────────────────────────────────────────
echo ""
echo "[..] nixos-install"

sudo nixos-install \
  --no-root-passwd \
  --flake "$WORKDIR#$HOST"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║      Installation complete!          ║"
echo "║                                      ║"
echo "║   Run: sudo reboot                   ║"
echo "╚══════════════════════════════════════╝"
echo ""
