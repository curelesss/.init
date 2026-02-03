#!/usr/bin/env bash
# run-clone-dotfiles.sh

set -euo pipefail

SCRIPT="./scripts/common/clone.dotfiles.sh"

echo "→ Running: $SCRIPT"
echo ""

"$SCRIPT"

echo ""
echo "Done."
