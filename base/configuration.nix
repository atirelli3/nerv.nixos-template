{ config, lib, pkgs, ... }:

{
  import = [ ./hardware-configuration.nix ];

  fileSystems = {
    "/boot" = lib.mkForce {
      device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
    "/" = lib.mkForce {
      device = "/dev/disk/by-label/NIXROOT";
      fsType = "ext4";
    };
  };

  swapDevices = [{ device = "/dev/disk/by-label/NIXSWAP"; }];

  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {};

  # TODO: For all users (aslo root) use zsh.



  system.stateVersion = "25.11";
}