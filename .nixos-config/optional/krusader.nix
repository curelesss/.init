{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    krusader
    kdePackages.breeze-icons
    kdePackages.oxygen-icons
  ];

  environment.sessionVariables = {
    XDG_DATA_DIRS = [ "${pkgs.kdePackages.breeze-icons}/share" ];
  };
}
