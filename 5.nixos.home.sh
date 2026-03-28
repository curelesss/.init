# ── Fix home directory ownership ──────────────────────────────────────────────
# createHome sometimes sets wrong ownership when mutableUsers = false.
# Correct it in /mnt before the system boots for the first time.
if [[ -d /mnt/home/fdong ]]; then
  sudo chown -R 1000:100 /mnt/home/fdong
  sudo chmod 755 /mnt/home/fdong
  ok "Home directory ownership fixed (fdong:users)"
fi
