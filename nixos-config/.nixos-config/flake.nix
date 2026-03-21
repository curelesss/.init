{
  description = "My first flake!";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    thorium.url = "github:Rishabh5321/thorium_flake";

    # use the following for unstable:
    # nixpkgs.url = "nixpkgs/nixos-unstable";

    # or any branch you want:
    # nixpkgs.url = "nixpkgs/{BRANCH-NAME}";
  };

  outputs = { self, nixpkgs, thorium, ... }:
    let
      lib = nixpkgs.lib;
    in {
      nixosConfigurations = {
        beelink = lib.nixosSystem {
          specialArgs = { inherit thorium; };
          system = "x86_64-linux";
          modules = [
            ./hosts/beelink/configuration.nix
          ];
      };
        nixos = lib.nixosSystem {
          specialArgs = { inherit thorium; };
          system = "x86_64-linux";
          modules = [
            ./hosts/nixos/configuration.nix
          ];
      };
    };
  };
}
