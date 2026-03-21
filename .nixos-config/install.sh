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
# /etc/nix is read-only in the live ISO — write to user config instead
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" \
  >> ~/.config/nix/nix.conf
export NIX_CONFIG="experimental-features = nix-command flakes"
echo "[ok] flakes enabled"

# ── 5. Wrapper flake — injects disk device via extendModules ──────────────────
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

echo "[..] locking wrapper flake"
nix flake lock "$WORKDIR" --override-input nixos-config "path:$FLAKE_DIR"
echo "[ok] wrapper flake ready"

# ── 6. Disko: partition, format, mount ────────────────────────────────────────
echo ""
echo "[..] disko — partitioning $DISK"
sudo nix run github:nix-community/disko/latest -- \
  --mode disko \
  --flake "$WORKDIR#$HOST"
echo "[ok] /mnt mounted"

# ── 7. nixos-install ──────────────────────────────────────────────────────────
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
