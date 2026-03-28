{ pkgs, lib, ... }:

{
  
  # Enabling GDM requires xserver to be on — set it here so default.nix
  # stays display-agnostic and this module is fully self-contained
  services.xserver.enable       = lib.mkForce true;
  services.xserver.xkb          = { layout = "us"; variant = ""; };

  # vmware Xorg driver only exists on x86_64 — on aarch64 (Apple Silicon)
  # VMware Fusion uses the modesetting driver via the kernel's DRM subsystem.
  # Explicitly setting videoDrivers on aarch64 causes a build failure because
  # xf86-video-vmware is not available for that platform.
  services.xserver.videoDrivers = lib.mkIf
    (pkgs.stdenv.hostPlatform.system == "x86_64-linux")
    [ "vmware" ];


  # 1. Enable GNOME and GDM
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # 2. Enable dconf system-wide
  programs.dconf.enable = true;

  # 4. GNOME-specific System Packages
  environment.systemPackages = with pkgs; [
    gnome-tweaks
    dconf-editor              # The "Registry Editor" for GNOME settings
    gnomeExtensions.kimpanel  # The IM panel for Fcitx5
    gtkmm3                    # fix copy/paste between host and vm
  ];

  # 3. Enable Browser Connector
  # services.gnome.gnome-browser-connector.enable = true;
  # 3.1 Firefox need the following extra setting to allow the browser to see the connector
  # nixpkgs.config.firefox.enableGnomeExtensions = true;
  
  # Note: This is a system-wide default. 
  # If you want it only for 'fdong', Home Manager is usually better,
  # but this works perfectly for a single-user system.
  services.desktopManager.gnome.extraGSettingsOverrides = ''
    [org.gnome.shell]
    enabled-extensions=['kimpanel@unassigned.user', 'gnome-browser-connector@gnome.org']
  '';
}
