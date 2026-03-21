{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];

  systemd.tmpfiles.rules = [
    "d /etc/wireguard 0700 root root -"
  ];

  networking.wg-quick.interfaces.wg0 = {
    configFile = "/etc/wireguard/wg0.conf";
    autostart = false;
  };
}
