{
  description = "NixOS system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, ... }: {

    nixosConfigurations = {

      # ── x86_64 VM — VMware on Windows ───────────────────────────────────────
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ./hosts/nixos/disko.nix
          ./hosts/nixos/default.nix
          ./modules/common/sys-packages.nix
          ./modules/common/user-shell-packages.nix
          ./modules/common/user-tilling-packages.nix
          ./modules/common/user-gui-packages.nix
          ./modules/common/fonts.nix
          ./modules/common/zsh.nix
          ./modules/common/im.nix
          ./modules/optional/gnome.nix
          ./modules/optional/niri.nix
          ./modules/optional/vmware-shares.nix
          ./modules/service/keyd.nix
        ];
      };

      # ── aarch64 VM — VMware Fusion on Apple M4 ──────────────────────────────
      nixos-arm = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          disko.nixosModules.disko
          ./hosts/nixos-arm/disko.nix
          ./hosts/nixos-arm/default.nix
          ./modules/common/sys-packages.nix
          ./modules/common/user-shell-packages.nix
          ./modules/common/user-tilling-packages.nix
          ./modules/common/user-gui-packages.nix
          ./modules/common/fonts.nix
          ./modules/common/zsh.nix
          ./modules/common/im.nix
          ./modules/optional/gnome.nix
          ./modules/optional/niri.nix
          # ./modules/optional/vmware-shares.nix
          ./modules/service/keyd.nix
        ];
      };

    };
  };
}
