#!/usr/bin/env bash
# Simple wrapper to run both scripts with sudo
# Save as: run-all.sh   (or any name you like)

set -euo pipefail

echo "Requesting sudo (needed to run the scripts)"
sudo -v || { echo "sudo failed"; exit 1; }

echo ""
echo "Setting Chinese Locale ..."
sudo ./scripts/arch/arch.0.1.locale.sh

echo ""
echo "Installing Fonts ..."
sudo ./scripts/arch/arch.0.2.font.sh

echo ""
echo "Setting several Chinese Characters ..."
sudo ./scripts/arch/arch.0.3.font.sc.sh

echo ""
echo "All scripts finished."
