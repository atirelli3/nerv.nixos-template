{
  description = "A minimal flake.nix for a SecureBoot-enabled NixOS machine";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {self, nixpkgs, lanzaboote, ... }@inputs: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # Assumes a standard x86 CPU
        modules = [
         ./configuration.nix
         lanzaboote.nixosModules.lanzaboote
         ./modules/lanza.nix
        ];
      };
    };
  };
}
