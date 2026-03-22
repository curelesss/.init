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
          ./modules/common/packages.nix
          ./modules/common/user-packages.nix
        ];
      };

      # ── aarch64 VM — VMware Fusion on Apple M4 ──────────────────────────────
      nixos-arm = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          disko.nixosModules.disko
          ./hosts/nixos-arm/disko.nix
          ./hosts/nixos-arm/default.nix
          ./modules/common/packages.nix
          ./modules/common/user-packages.nix
        ];
      };

    };
  };
}
