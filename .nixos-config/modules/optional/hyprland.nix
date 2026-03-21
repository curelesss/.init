{ config, pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.systemPackages = with pkgs; [
    kitty              # default terminal
    wl-clipboard       # clipboard
    hyprlock           # screen locker
    # --- Core ---
    xdg-desktop-portal-hyprland   # screen sharing
    qt6.qtwayland
    # --- Session & Authentication ---
    hyprpolkitagent               # authentication agent
    hyprlock                      # screen locker
    hypridle                      # idle management daemon
    # --- Interface ---
    waybar                        # status bar
    rofi                  # app launcher (wayland version)
    swww                          # wallpaper daemon
    hyprpaper
    matugen                       # material you color generation
    # --- Notification Daemon ---
    # mako                        # notification daemon
    # swaync
    swaynotificationcenter
    #swayNotificationCenter        # swaync
    # --- OSD Daemon ---
    swayosd
    # --- CLI Utilities ---
    brightnessctl                 # brightness
    # --- Sound ---
    pamixer                       # pipewire volume control
    libpulseaudio                 # libpulse
    pipewire                      # pipewire-pulse (enable services.pipewire.pulse.enable = true instead)
    # helvum                        # or use wiremix if available
    # --- TUI Utilities ---
    impala                        # WiFi TUI (Rust)
    bluetui                       # Bluetooth TUI (Rust)
  ];

  # hint electron apps to use wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
