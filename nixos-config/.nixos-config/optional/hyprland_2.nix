{ config, pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    WLR_RENDERER = "gles2";
    LIBGL_ALWAYS_SOFTWARE = "1";  # force software rendering in VM
  };

  environment.systemPackages = with pkgs; [
    kitty              # default terminal
    hyprland-qtutils
  ];

  # hint electron apps to use wayland
  # environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
