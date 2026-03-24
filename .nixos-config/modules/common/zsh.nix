{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = lib.mkForce true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
  };

  users.users.fdong = {
    shell = lib.mkForce pkgs.zsh;
  };

  environment.systemPackages = with pkgs; [
    zsh-powerlevel10k
  ];
}
