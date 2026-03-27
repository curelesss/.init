{ pkgs, ... }: {

  users.users.fdong.packages = with pkgs; [

    #############
    ### Shell ###
    #############

    # --- Emulator ---
    kitty
    wezterm
    foot
    alacritty
    ghostty

    # --- CLI Search ---
    fd
    ripgrep
    fzf

    # --- Modern CLI Alternatives ---
    bat
    eza
    zoxide

    # --- Archives ---
    p7zip
    unrar

    # --- Disk util ---
    duf
    ncdu

    # --- Wayland Utilities ---
    wl-clipboard
    wlr-randr

    # --- Documentation ---
    tealdeer

    # --- System Info ---
    fastfetch
    btop

    # --- git ---
    lazygit

    # --- Editor ---
    neovim

    # --- Dependencies ---
    gcc

  ];
}
