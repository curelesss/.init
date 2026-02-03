#!/usr/bin/env bash
# =============================================================================
# clone-dotfiles.sh
# Idempotently clones git@github.com:curelesss/.dotfiles.git
# Shows full git clone output when cloning
# =============================================================================

set -u -e -o pipefail

REPO="git@github.com:curelesss/.password-store.git"
DEST="${HOME}/.password-store"  # ← Change this if you want it somewhere else

# ──────────────────────────────────────────────
# Check if already cloned
# ──────────────────────────────────────────────
if [[ -d "$DEST" && -d "$DEST/.git" ]]; then
    echo "→ Directory $DEST already exists and looks like a git repository."
    echo "  Clone is idempotent → skipping."
    echo ""
    echo "  You can update manually with:"
    echo "    git -C $DEST pull"
    exit 0
fi

# ──────────────────────────────────────────────
# Clone with real output
# ──────────────────────────────────────────────
echo "→ Cloning dotfiles..."
echo "  From: $REPO"
echo "  Into: $DEST"
echo ""

# Create parent directory if needed
mkdir -p "$(dirname "$DEST")" || { echo "Error: failed to create parent dir" >&2; exit 1; }

# Run git clone and let it print everything directly
git clone "$REPO" "$DEST"

# Check exit status of git clone
if [[ $? -eq 0 ]]; then
    echo ""
    echo "→ Successfully cloned → $DEST"
    echo "  Done."
else
    echo ""
    echo "Error: git clone failed" >&2
    exit 1
fi

