{ config, lib, pkgs, ... }:

{
  import = [ ./hardware-configuration.nix ];

  fileSystems = {
    "/boot" = lib.mkForce {
      device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
    "/nix" = lib.mkForce {
      device = "/dev/disk/by-label/NIXSTORE";
      fsType = "ext4";
      neededForBoot = true;
    };
    "/persist" = lib.mkForce {
      device = "/dev/disk/by-label/NIXPERSIST";
      fsType = "ext4";
      neededForBoot = true;
    };

    "/" = lib.mkForce {
      device = "/dev/disk/by-label/NIXROOT";
      fsType = "tmpfs";
      options = [ "defaults" "size=SIZE" "mode=755" ];
    };
    "/home" = lib.mkForce {
      device = "/dev/disk/by-label/NIXHOME";
      fsType = "tmpfs";
      options = [ "defaults" "size=SIZE" "mode=755" ];
    };
  };

  swapDevices = [{
    device = "/dev/disk/by-partuuid/UUID";
    randomEncryption.enable = true;
  }];

  environment.persistence = {
    "/persist" = {};
    "/home" = {};
  };

  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {};

  # TODO: For all users (aslo root) use zsh.


  system.stateVersion = "25.11";
}