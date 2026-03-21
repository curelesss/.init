#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$SCRIPT_DIR"

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

# ── 3. Confirm ─────────────────────────────────────────────────────────────────
echo ""
echo "  Flake : $FLAKE_DIR"
echo "  Host  : $HOST"
echo "  Disk  : $DISK"
echo ""
echo "  !! ALL DATA ON $DISK WILL BE PERMANENTLY ERASED !!"
echo ""
read -rp "  Type YES to continue: " confirm
[[ "$confirm" != "YES" ]] && { echo "Aborted."; exit 1; }

# ── 4. Enable flakes ───────────────────────────────────────────────────────────
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" \
  >> ~/.config/nix/nix.conf

sudo mkdir -p /root/.config/nix
echo "experimental-features = nix-command flakes" \
  | sudo tee /root/.config/nix/nix.conf > /dev/null

export NIX_CONFIG="experimental-features = nix-command flakes"
echo "[ok] flakes enabled (user + root)"

# ── 5. Write the disk device into disko.nix directly ──────────────────────────
# Instead of a wrapper flake (which causes narHash assertion errors in
# nixos-install), we patch the actual disko.nix default value in a temp copy
# of the whole flake, so there is only ONE flake with ONE consistent lock.

WORKDIR=$(mktemp -d /tmp/nixos-install-XXXXXX)
trap 'rm -rf "$WORKDIR"' EXIT

echo "[..] copying flake to $WORKDIR"

# Copy the entire flake directory
cp -r "$FLAKE_DIR/." "$WORKDIR/"

# Replace the default disk device value in the copied disko.nix
DISKO_FILE="$WORKDIR/hosts/$HOST/disko.nix"

if [[ ! -f "$DISKO_FILE" ]]; then
  echo "Error: $DISKO_FILE not found."
  exit 1
fi

# Inject the actual disk as the default, overriding whatever was there
# We add an extraModule inline so the option value is forced at eval time
cat > "$WORKDIR/disk-override.nix" <<EOF
{ ... }: {
  myConfig.diskDevice = "$DISK";
}
EOF

# Patch the flake.nix in the copy to include the disk-override module
sed -i "s|./hosts/$HOST/disko.nix|./hosts/$HOST/disko.nix\n        ./disk-override.nix|" \
  "$WORKDIR/flake.nix"

echo "[ok] disk device '$DISK' injected into flake copy"

# ── 6. Read disko revision from flake.lock ────────────────────────────────────
DISKO_REV=$(awk '/"disko"/{found=1} found && /"rev"/{
  match($0, /"rev": "([^"]+)"/, a); print a[1]; exit}' \
  "$WORKDIR/flake.lock")

if [[ -z "$DISKO_REV" || "$DISKO_REV" == "null" ]]; then
  echo "Error: could not read disko revision from flake.lock"
  exit 1
fi
echo "[ok] disko revision: $DISKO_REV"

# ── 7. Disko: partition, format, mount ────────────────────────────────────────
echo ""
echo "[..] disko — partitioning $DISK"

sudo nix run \
  --extra-experimental-features "nix-command flakes" \
  "github:nix-community/disko/$DISKO_REV" -- \
  --mode disko \
  --flake "$WORKDIR#$HOST"

echo "[ok] /mnt mounted"

# ── 8. nixos-install ──────────────────────────────────────────────────────────
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
