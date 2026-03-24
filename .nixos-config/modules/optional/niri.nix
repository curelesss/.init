{ pkgs, lib, ... }:
{
  programs.niri.enable = true;

  # recommended companion services
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.swaylock = {};

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  environment.systemPackages = with pkgs; [
    alacritty    # Super+T terminal
    fuzzel       # Super+D launcher
  ];
}
