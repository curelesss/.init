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

# ── 3. China mirrors ──────────────────────────────────────────────────────────
echo ""
echo "Additional binary cache mirrors (useful in China):"
echo "  1) mirrors.ustc.edu.cn"
echo "  2) mirrors.tuna.tsinghua.edu.cn"
echo "  both will be added as extra substituters before cache.nixos.org"
echo ""
read -rp "Use China mirrors? [y/N]: " use_mirrors
USE_MIRRORS=false
[[ "${use_mirrors,,}" == "y" || "${use_mirrors,,}" == "yes" ]] && USE_MIRRORS=true

if $USE_MIRRORS; then
  echo "[ok] China mirrors will be used"
else
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

# ── 5. Enable flakes ───────────────────────────────────────────────────────────
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" \
  >> ~/.config/nix/nix.conf

sudo mkdir -p /root/.config/nix
echo "experimental-features = nix-command flakes" \
  | sudo tee /root/.config/nix/nix.conf > /dev/null

export NIX_CONFIG="experimental-features = nix-command flakes"
echo "[ok] flakes enabled (user + root)"

# ── 6. Apply China mirrors to the live session if requested ───────────────────
if $USE_MIRRORS; then
  MIRROR_CONF="extra-substituters = https://mirrors.ustc.edu.cn/nix-channels/store https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store
extra-trusted-substituters = https://mirrors.ustc.edu.cn/nix-channels/store https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"

  # User config
  echo "$MIRROR_CONF" >> ~/.config/nix/nix.conf

  # Root config (used by sudo nix run and sudo nixos-install)
  printf "\n%s\n" "$MIRROR_CONF" | sudo tee -a /root/.config/nix/nix.conf > /dev/null

  export NIX_CONFIG="experimental-features = nix-command flakes
extra-substituters = https://mirrors.ustc.edu.cn/nix-channels/store https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store
extra-trusted-substituters = https://mirrors.ustc.edu.cn/nix-channels/store https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"

  echo "[ok] China mirrors applied to live session"
fi

# ── 7. Copy flake and inject disk device ──────────────────────────────────────
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

# ── 8. Read disko revision from flake.lock ────────────────────────────────────
DISKO_REV=$(awk '/"disko"/{found=1} found && /"rev"/{
  match($0, /"rev": "([^"]+)"/, a); print a[1]; exit}' \
  "$WORKDIR/flake.lock")

if [[ -z "$DISKO_REV" || "$DISKO_REV" == "null" ]]; then
  echo "Error: could not read disko revision from flake.lock"
  exit 1
fi
echo "[ok] disko revision: $DISKO_REV"

# ── 9. Disko: partition, format, mount ────────────────────────────────────────
echo ""
echo "[..] disko — partitioning $DISK"

DISKO_CMD=(
  sudo nix run
  --extra-experimental-features "nix-command flakes"
)

if $USE_MIRRORS; then
  DISKO_CMD+=(
    --extra-substituters "https://mirrors.ustc.edu.cn/nix-channels/store https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    --extra-trusted-substituters "https://mirrors.ustc.edu.cn/nix-channels/store https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  )
fi

DISKO_CMD+=(
  "github:nix-community/disko/$DISKO_REV" --
  --mode disko
  --flake "$WORKDIR#$HOST"
)

"${DISKO_CMD[@]}"
echo "[ok] /mnt mounted"

# ── 10. nixos-install ─────────────────────────────────────────────────────────
echo ""
echo "[..] nixos-install"

INSTALL_CMD=(
  sudo nixos-install
  --no-root-passwd
  --flake "$WORKDIR#$HOST"
)

if $USE_MIRRORS; then
  INSTALL_CMD+=(
    --option extra-substituters "https://mirrors.ustc.edu.cn/nix-channels/store https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    --option extra-trusted-substituters "https://mirrors.ustc.edu.cn/nix-channels/store https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  )
fi

"${INSTALL_CMD[@]}"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║      Installation complete!          ║"
echo "║                                      ║"
echo "║   Run: sudo reboot                   ║"
echo "╚══════════════════════════════════════╝"
echo ""
