{ config, pkgs, ... }:

{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5"; # use `enabled` instead if on older NixOS
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      fcitx5-gtk
      (fcitx5-rime.override {
        rimeDataPkgs = [ rime-data rime-ice ]; # rime-data provides base schemas; rime-ice adds 雾凇拼音
      })
    ];
  };

  # Place rime config in the correct location (~/.local/share/fcitx5/rime/)
  system.activationScripts.fcitx5-rime-config = {
    text = ''
      mkdir -p /home/fdong/.local/share/fcitx5/rime
      cat > /home/fdong/.local/share/fcitx5/rime/default.custom.yaml << 'EOF'
      patch:
        schema_list:
          - schema: rime_ice
      EOF
      chown -R fdong:users /home/fdong/.local/share/fcitx5
    '';
  };

  environment.systemPackages = with pkgs; [
    gnomeExtensions.kimpanel
    qt6Packages.fcitx5-configtool # renamed from fcitx5-configtool in nixpkgs 25.11
  ];
}
