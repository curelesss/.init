#!/usr/bin/env bash
set -u -e

PACKAGES=(
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-extra
)

if [[ $EUID -ne 0 ]]; then
    echo "Elevating privileges..."
    exec sudo --preserve-env=TERM "${BASH_SOURCE[0]}" "$@"
fi

echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃        Installing full Noto font family        ┃"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
echo

for pkg in "${PACKAGES[@]}"; do
    echo "→ Checking/installing: $pkg"
    echo "───────────────────────────────────────────────"

    # Show full detailed output for each package
    if pacman -S --needed --noconfirm "$pkg"; then
        echo "  → Success"
    else
        echo "  → Failed or already installed (see output above)"
    fi
    echo
done

echo "Final status:"
echo "───────────────────────────────────────────────"
pacman -Q "${PACKAGES[@]}" 2>/dev/null || true

echo
echo "Font cache:"
echo "───────────────────────────────────────────────"
echo "Running fc-cache -fv (force rebuild + verbose output)..."
echo
fc-cache -fv | sed 's/^/  /'

echo
echo "Done! Fonts should be available."
echo "Tip: Restart graphical applications or log out/in."
echo
