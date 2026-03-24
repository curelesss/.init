{ pkgs, ... }: {

  users.users.fdong.packages = with pkgs; [

    # --- App Launcher ---
    fuzzel		# Niri default launcher
    rofi

    # --- Menu Bar ---
    waybar

    # --- Color Theme ---
    matugen

    # --- Wallpaper ---
    swww
    swaybg

    # --- Notification Center ---
    swaynotificationcenter
    mako

    # --- OSD ---
    swayosd

    # --- Brightness ---
    brightnessctl

    # --- Audio ---
    pamixer		# CLI mixer for PulseAudio
    wiremix		# TUI audio mixer for PipeWire

    # --- WIFI ---
    impala		# TUI WIFI manager with iwd backend

    # --- WIFI ---
    bluetui		# TUI Bluetooth manager

    # --- Screen Lock ---
    swaylock

    # --- idle management ---
    swayidle

    # --- XWayland support ---
    xwayland-satellite
  ];

}
