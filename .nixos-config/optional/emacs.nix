{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    emacs-gtk       # or emacs29 for terminal-only
    # optional but recommended
    sqlite          # for org-roam
    imagemagick     # for image support
    pandoc          # for document export
  ];
}
