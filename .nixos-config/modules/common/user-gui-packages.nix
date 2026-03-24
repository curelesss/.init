{ pkgs, ... }: {

  users.users.fdong.packages = with pkgs; [

    # --- File Browser ---
    nautilus

    # --- Browser ---
    brave
    firefox

  ];

}
