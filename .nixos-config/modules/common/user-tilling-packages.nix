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

    # --- Notification Center ---
    swaynotificationcenter
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
  ];

}
