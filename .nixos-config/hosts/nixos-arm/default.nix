{ config, pkgs, lib, ... }: {

  networking.hostName = "nixos-arm";
  networking.networkmanager.enable = true;

  # programs.zsh.enable = true;

  # ── Bootloader: systemd-boot for UEFI on ARM ────────────────────────────────
  # VMware Fusion on Apple Silicon uses UEFI exclusively — no legacy BIOS.
  # systemd-boot is simpler and more reliable than GRUB EFI on aarch64.
  boot.loader.systemd-boot = {
    enable       = true;
    configurationLimit = 10;       # keep last 10 generations in boot menu
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Kernel: use latest for best aarch64 VMware Fusion support ───────────────
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ── Kernel modules for VMware on ARM ────────────────────────────────────────
  # VMware Fusion on Apple Silicon presents a slightly different virtual
  # hardware profile than VMware on x86 — these modules cover both cases
  boot.initrd.availableKernelModules = [
    "xhci_pci"    # USB 3.0 controller
    "usb_storage" # USB storage devices
    "sd_mod"      # SCSI disk driver
    "sr_mod"      # SCSI CD-ROM driver
    "virtio_pci"  # VirtIO PCI bus (used by Fusion on ARM)
    "virtio_blk"  # VirtIO block device
    "virtio_net"  # VirtIO network
  ];

  # ── VMware guest tools ───────────────────────────────────────────────────────
  virtualisation.vmware.guest.enable = true;

  # SSD/virtual disk trim
  services.fstrim.enable = true;

  # ── Locale and time ──────────────────────────────────────────────────────────
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT    = "zh_CN.UTF-8";
    LC_MONETARY       = "zh_CN.UTF-8";
    LC_NAME           = "zh_CN.UTF-8";
    LC_NUMERIC        = "zh_CN.UTF-8";
    LC_PAPER          = "zh_CN.UTF-8";
    LC_TELEPHONE      = "zh_CN.UTF-8";
    LC_TIME           = "zh_CN.UTF-8";
  };

  # ── Display ──────────────────────────────────────────────────────────────────
  services.xserver.enable = true;

  services.xserver.xkb = {
    layout  = "us";
    variant = "";
  };

  # ── Desktop environment ──────────────────────────────────────────────────────
  # Use the same desktop as the x86 host — defined in your gnome/hyprland modules
  # Uncomment whichever you use:
  services.xserver.displayManager.gdm.enable  = true;
  services.xserver.desktopManager.gnome.enable = true;

  # ── Sound ────────────────────────────────────────────────────────────────────
  services.pulseaudio.enable = false;
  security.rtkit.enable      = true;
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = false;   # no 32-bit on ARM
    pulse.enable      = true;
  };

  # ── Printing ─────────────────────────────────────────────────────────────────
  services.printing.enable = true;

  # ── User ─────────────────────────────────────────────────────────────────────
  users.mutableUsers = false;
  users.users.fdong = {
    isNormalUser       = true;
    extraGroups        = [ "wheel" "networkmanager" "audio" "video" ];
    hashedPasswordFile = "/etc/nixos/fdong.hash";
    shell              = pkgs.zsh;
    home               = "/home/fdong";
    createHome         = true;
  };

  security.sudo.wheelNeedsPassword = true;

  # ── SSH ──────────────────────────────────────────────────────────────────────
  services.openssh = {
    enable                        = true;
    settings.PasswordAuthentication = true;
  };

  # ── Nix settings ─────────────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store   = true;
    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  # ── Prevent VMware display freeze on idle ────────────────────────────────────
  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowSuspendThenHibernate=no
    AllowHybridSleep=no
  '';

  services.xserver.serverFlagsSection = ''
    Option "BlankTime"   "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime"     "0"
  '';

  services.logind = {
    lidSwitch              = "ignore";
    lidSwitchExternalPower = "ignore";
    extraConfig            = ''
      IdleAction=ignore
      IdleActionSec=0
    '';
  };

  # ── Misc ─────────────────────────────────────────────────────────────────────
  programs.firefox.enable    = true;
  nixpkgs.config.allowUnfree = true;

  programs.gnupg.agent.enable = true;

  system.stateVersion = "24.11";
}
