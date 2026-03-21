{ config, pkgs, lib, ... }: 

{
  # Syste wide packages
  environment.systemPackages = with pkgs; [
    git		
    vim
    ansible
    unzip 	# unarchive personal key
    gnupg	  # gnupg key
    pass	  # password-store
    stow
    gtkmm3  # fix clipboard between host and vm
  ];


}
