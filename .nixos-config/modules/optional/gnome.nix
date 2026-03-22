{ pkgs, lib, ... }:

{
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
