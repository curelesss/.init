{ config, pkgs, ... }:

{
  # enable shotkey daemon along with hyper key cfg (keyd will be auto installed as the dependency)
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        extraConfig = ''
          [main]
          capslock = overload(hyper, esc)

          [hyper:C-A-S]
          h = left
          j = down
          k = up
          l = right
        '';
      };
    };
  };

  # fix for palm rejection issue with keyd virtual keyboard on GNOME/libinput
  environment.etc."libinput/local-overrides.quirks".text = ''
    [Serial Keyboards]
    MatchUdevType=keyboard
    MatchName=keyd virtual keyboard
    AttrKeyboardIntegration=internal
  '';
}
