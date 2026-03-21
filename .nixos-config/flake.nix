{
  description = "My NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./hosts/nixos/disko.nix
        ./hosts/nixos/default.nix
        ./modules/common/sys-packages.nix
        ./modules/common/user-packages.nix
        ./modules/optional/gnome.nix
      ];
    };
  };

  # outputs = { self, nixpkgs, disko, ... }:
  #   let
  #     lib = nixpkgs.lib;
  #   in {
  #     nixosConfigurations = {
  #       beelink = lib.nixosSystem {
  #         specialArgs = { inherit thorium; };
  #         system = "x86_64-linux";
  #         modules = [
  #           ./hosts/beelink/configuration.nix
  #         ];
  #     };
  #       nixos = lib.nixosSystem {
  #         specialArgs = { inherit thorium; };
  #         system = "x86_64-linux";
  #         modules = [
  #           ./hosts/nixos/configuration.nix
  #         ];
  #     };
  #   };
  # };
}
