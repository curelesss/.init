{ pkgs, ... }: {
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    nerd-fonts.mononoki
    nerd-fonts.symbols-only
    lxgw-wenkai
  ];

  # This ensures basic compatibility for apps that don't use fontconfig
  fonts.enableDefaultPackages = true;
}
