# NixOS

## GUI Installation

- 1.0 Using `Graphical ISO image` with custom `substitiuters`
  - 1.1 checking symlink status of `/etc/nix/nix.conf`
  ```bash
  ls -la /etc/nix/nix.conf
  lrwxrwxrwx 1 root root 24 Mar 19  2026 /etc/nix/nix.conf -> /etc/static/nix/nix.conf
  ```
  - 1.2 create `/tmp/nix.conf`
  ```bash
  cat > /tmp/nix.conf <<EOF
  experimental-features = nix-command flakes
  substituters = https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://cache.nixos.org/
  trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
  trusted-users = root nixos
  EOF
  ```
  - 1.3 varify
  ```bash
  cat /etc/nix/nix.conf
  ```
  - 1.4 Restart daemon
  ```bash
  sudo systemctl restart nix-daemon
  ```
  - 1.5 Confirm daemon picked it up
  ```bash
  sudo nix show-config | grep substituters
  ```
  - 1.6 re-launch graphical installer and install NixOS

- 2.0 Boot into NixOS and Edit `/etc/nixos/configuration.nix`
  
  - 2.1 add system packages
    - `vim`
    - `git`
    - `ansible` - for various automation tasks
    - `unzip` - unzip gnupg achive
    - `gnupg` & `pass` - utility for personal password store
    - `stow` - install nixos-config 

  - 2.2 modify hostname (which flake to use)
    - `networking.hostName = "nixos";`
  
  - 2.3 enable Flake (might be optional)
    - `nix.settings.experimental-features = ["nix-command" "flakes"];`

  - 2.4 add custom `substituters`
  ```nix
  nix.settings = {
    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"     # 中科大（可优先）
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"  # 清华
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };
  ```
  
  - 2.4 rebuild the system for 2.1 - 2.3
    - `sudo nixos-rebuild switch`
  
- 3. Setup Github ssh auth / gnupg key / password-store

### Wireguard

- Setup Wireguard connection
  - `.init` repo - `nixos.o.wireguard.sh`
    - source file: ansible vault encrypt `.dotfiles/wireguard/wg0.conf`
    - target install directory: `/etc/wireguard/wg0.conf`

- Command
  - `sudo wg-quick up wg0`    # connect
  - `sudo wg-quick down wg0`  # disconnect
  - `sudo wg show`            # check status
