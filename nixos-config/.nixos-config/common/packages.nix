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

  # Package for user level
  _module.args.myAppList = with pkgs; [

    #############
    ### Shell ###
    #############

    # --- Dotfiles ---
    stow

    # --- Emulator ---
    kitty         # tmux function replacement
    wezterm       # cross platform, MS-Windows version
    foot          # wayland native
    alacritty

    # --- CLI Search ---
    fd            # simple/fast find
    ripgrep       # fast grep (rg)
    fzf           # fuzzy finder

    # --- Modern CLI Alternatives ---
    bat           # cat clone with wings
    eza           # modern ls
    zoxide        # smarter cd command

    # --- Archives ---
    #  using unrar for rar file extraction
    #  using unzip for normal archive task (unzip installed as system package)
    #  using 7zip for password protected archive
    p7zip
    unrar

    # --- Dish util --- 
    duf           # disk usage utility
    ncdu          # disk usage utility

    # --- Wayland Utilities ---
    wl-clipboard  # Wayland clipboard
    wlr-randr     # Wayland output manager

    # --- Documentation ---
    tealdeer      # Fast tldr client in Rust

    # --- System Info & Eye Candy ---
    fastfetch     # maintained neofetch alternative
    btop

    # --- Interface ---
    waybar                        # status bar
    rofi                          # app launcher
    swww                          # wallpaper daemon
    matugen                       # package moved from aur to main repo
    swaynotificationcenter        # notification daemon
    swayosd                       # osd daemon
    brightnessctl                 # brightness
    pamixer                       # pipwire volume control
    wiremix                       # volume control TUI (Rust)
    impala                        # WiFi TUI (Rust)
    bluetui                       # Bluetooth TUI (Rust)

    # --- git ---
    lazygit

    # --- Editor ---
    neovim

    # --- Dependencies ---
    gcc		# for neovim treesitter

    ###########
    ### GUI ###
    ###########

    # --- File Browser ---
    nautilus

    # --- Browser ---
    brave

    # --- Misc ---
    wechat
    # karing
    # synology-drive-client

    ################
    ### Hyprland ###
    ################

    # --- Core ---
    hyprland
    xdg-desktop-portal-hyprland   # screen sharing  

    # --- Session & Authetication ---
    hyprpolkitagent               # authentication agent
    hyprlock                      # screen Locker
    hypridle                      # idle management daemon
  ];

}
