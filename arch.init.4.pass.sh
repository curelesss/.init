#!/bin/sh

set -u -e -o pipefail

# ──────────────────────────────────────────────
# Auto elevate to root if not already root
# ──────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo "This script needs root privileges to install packages."
    echo "Re-executing with sudo..."
    exec sudo -- "$BASH_SOURCE" "$@"
    # exec never returns if successful
    echo "Failed to elevate privileges" >&2
    exit 1
fi

. ./scripts/arch/arch.install.gnupg.sh
. ./scripts/arch/arch.install.pass.sh
