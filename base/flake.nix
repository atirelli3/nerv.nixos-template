{
  description = "NixOS system configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Secure Boot bootloader — replaces systemd-boot when modules/secureboot.nix is loaded.
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, lanzaboote, ... }: {
    nixosConfigurations = {

      nixos-base = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          lanzaboote.nixosModules.lanzaboote
          ../modules/secureboot.nix
          ../modules/zsh.nix
          ../modules/openssh.nix
          ../modules/hardware.nix
          ../modules/printing.nix
        ];
      };

    };
  };
}
