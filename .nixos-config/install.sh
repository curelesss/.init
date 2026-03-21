#!/usr/bin/env bash
set -euo pipefail

# Print each command before executing so we see exactly where it fails
set -x

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$SCRIPT_DIR"

set +x
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
set -x
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" \
  >> ~/.config/nix/nix.conf

sudo mkdir -p /root/.config/nix
echo "experimental-features = nix-command flakes" \
  | sudo tee /root/.config/nix/nix.conf > /dev/null

export NIX_CONFIG="experimental-features = nix-command flakes"
set +x
echo "[ok] flakes enabled (user + root)"

# ── 5. Wrapper flake ───────────────────────────────────────────────────────────
WORKDIR=$(mktemp -d /tmp/nixos-install-XXXXXX)
trap 'rm -rf "$WORKDIR"' EXIT

cat > "$WORKDIR/flake.nix" <<EOF
{
  inputs.nixos-config.url = "path:$FLAKE_DIR";

  outputs = { self, nixos-config, ... }: {
    nixosConfigurations.$HOST =
      nixos-config.nixosConfigurations.$HOST.extendModules {
        modules = [ { myConfig.diskDevice = "$DISK"; } ];
      };
  };
}
EOF

cp "$FLAKE_DIR/flake.lock" "$WORKDIR/flake.lock"
echo "[ok] wrapper flake written to $WORKDIR"

# ── 6. Read disko revision ─────────────────────────────────────────────────────
echo ""
echo "[..] reading disko revision from flake.lock"

# Print the raw lock content around disko for debugging
echo "--- flake.lock disko section ---"
grep -A10 '"disko"' "$FLAKE_DIR/flake.lock" || echo "(disko not found in lock)"
echo "--- end ---"

# Try multiple patterns to be robust against lock format variations
DISKO_REV=""

# Pattern 1: inside a "locked" block after "disko"
DISKO_REV=$(awk '/"disko"/{found=1} found && /"rev"/{
  match($0, /"rev": "([^"]+)"/, a); print a[1]; exit}' \
  "$FLAKE_DIR/flake.lock")

if [[ -z "$DISKO_REV" ]]; then
  echo "Error: could not extract disko revision from flake.lock"
  echo "Please paste the output above and report it."
  exit 1
fi

echo "[ok] disko revision: $DISKO_REV"

# ── 7. Disko: partition, format, mount ────────────────────────────────────────
echo ""
echo "[..] disko — partitioning $DISK"

set -x
sudo nix run \
  --extra-experimental-features "nix-command flakes" \
  "github:nix-community/disko/$DISKO_REV" -- \
  --mode disko \
  --flake "$WORKDIR#$HOST"
set +x

echo "[ok] /mnt mounted"

# ── 8. nixos-install ──────────────────────────────────────────────────────────
echo ""
echo "[..] nixos-install"

set -x
sudo nixos-install \
  --no-root-passwd \
  --flake "$WORKDIR#$HOST"
set +x

echo ""
echo "╔══════════════════════════════════════╗"
echo "║      Installation complete!          ║"
echo "║                                      ║"
echo "║   Run: sudo reboot                   ║"
echo "╚══════════════════════════════════════╝"
echo ""
