{ config, pkgs, lib, ... }: {

  networking.hostName = "nixos-arm";
  networking.networkmanager.enable = true;

  # ── Bootloader: systemd-boot UEFI (Apple Silicon / ARM) ─────────────────────
  boot.loader.systemd-boot = {
    enable             = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Kernel ───────────────────────────────────────────────────────────────────
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "usb_storage"
    "sd_mod"
    "sr_mod"
    "virtio_pci"
    "virtio_blk"
    "virtio_net"
  ];

  # ── VMware guest tools ───────────────────────────────────────────────────────
  virtualisation.vmware.guest.enable = true;
  services.fstrim.enable             = true;

  # ── Locale and time ──────────────────────────────────────────────────────────
  time.timeZone    = "Asia/Shanghai";
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

  # ── Desktop ──────────────────────────────────────────────────────────────────
  services.xserver.displayManager.gdm.enable   = true;
  services.xserver.desktopManager.gnome.enable = true;

  # ── Sound ────────────────────────────────────────────────────────────────────
  services.pulseaudio.enable = false;
  security.rtkit.enable      = true;
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = false;    # no 32-bit compat on aarch64
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
    shell              = pkgs.bash;
    home               = "/home/fdong";
    createHome         = true;
  };

  security.sudo.wheelNeedsPassword = true;

  # ── SSH ──────────────────────────────────────────────────────────────────────
  services.openssh = {
    enable                          = true;
    settings.PasswordAuthentication = true;
  };

  # ── Prevent VMware display freeze on idle ────────────────────────────────────

  # Disable OS-level suspend — VMware manages power at the hypervisor level
  systemd.sleep.settings.Sleep = {
    AllowSuspend              = "no";
    AllowHibernation          = "no";
    AllowSuspendThenHibernate = "no";
    AllowHybridSleep          = "no";
  };

  # Disable X11 screen blanking and DPMS so the VMware SVGA driver does not
  # lose its display state when the screen would otherwise blank
  services.xserver.serverFlagsSection = ''
    Option "BlankTime"   "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime"     "0"
  '';

  # Disable logind idle action so the session never auto-locks from inactivity
  services.logind = {
    lidSwitch              = "ignore";
    lidSwitchExternalPower = "ignore";
    settings.Login = {
      IdleAction    = "ignore";
      IdleActionSec = "0";
    };
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

  # ── Misc ─────────────────────────────────────────────────────────────────────
  programs.firefox.enable    = true;
  nixpkgs.config.allowUnfree = true;
  programs.gnupg.agent.enable = true;

  system.stateVersion = "24.11";
}
