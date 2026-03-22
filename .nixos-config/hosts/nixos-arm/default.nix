{ config, pkgs, lib, ... }: {

  networking.hostName = "nixos-arm";
  networking.networkmanager.enable = true;

  # ── Bootloader ───────────────────────────────────────────────────────────────
  boot.loader.systemd-boot = {
    enable             = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Kernel ───────────────────────────────────────────────────────────────────
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.availableKernelModules = [
    "xhci_pci" "usb_storage" "sd_mod" "sr_mod"
    "virtio_pci" "virtio_blk" "virtio_net"
  ];

  # ── VMware ───────────────────────────────────────────────────────────────────
  virtualisation.vmware.guest.enable = true;
  services.fstrim.enable             = true;

  # ── Locale ───────────────────────────────────────────────────────────────────
  time.timeZone      = "Asia/Shanghai";
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
  services.xserver.xkb = { layout = "us"; variant = ""; };

  # ── Desktop — updated option paths for nixos-unstable ────────────────────────
  services.displayManager.gdm.enable    = true;   # was services.xserver.displayManager.gdm
  services.desktopManager.gnome.enable  = true;   # was services.xserver.desktopManager.gnome

  # ── Sound ────────────────────────────────────────────────────────────────────
  services.pulseaudio.enable = false;
  security.rtkit.enable      = true;
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = false;
    pulse.enable      = true;
  };

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

  # ── Prevent VMware display freeze — updated option paths ─────────────────────
  systemd.sleep.settings.Sleep = {
    AllowSuspend              = "no";
    AllowHibernation          = "no";
    AllowSuspendThenHibernate = "no";
    AllowHybridSleep          = "no";
  };

  services.xserver.serverFlagsSection = ''
    Option "BlankTime"   "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime"     "0"
  '';

  services.logind.settings.Login = {
    HandleLidSwitch             = "ignore";   # was lidSwitch
    HandleLidSwitchExternalPower = "ignore";  # was lidSwitchExternalPower
    IdleAction                  = "ignore";
    IdleActionSec               = "0";
  };

  # ── Nix ──────────────────────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store   = true;
    download-buffer-size  = 524288000;
    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  programs.firefox.enable     = true;
  nixpkgs.config.allowUnfree  = true;
  programs.gnupg.agent.enable = true;

  system.stateVersion = "24.11";
}
