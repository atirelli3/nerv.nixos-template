{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "nixos-base";
    networkmanager.enable = true;
  };

  # lib.mkForce overrides the Disko-generated mounts — keep labels in sync with disko-configuration.nix.
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

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    initrd = {
      systemd.enable   = true;   # required for services.lvm and crypttabExtraOpts
      services.lvm.enable = true;
      kernelModules = [ "dm-snapshot" "cryptd" ];  # LVM-on-LUKS snapshots and async dm-crypt
      luks.devices."cryptroot" = {
        device = "/dev/disk/by-label/NIXLUKS";
        preLVM = true;
        allowDiscards = true;  # TRIM pass-through for SSDs
      };
    };
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";
  # Terminus gives the best unicode coverage available in TTY (PSF format).
  # Nerd Font glyphs only render in graphical terminal emulators, not in TTY.
  console = {
    font     = "ter-v18n";
    packages = [ pkgs.terminus_font ];

    # Uncomment exactly one layout:
    keyMap = "us-acentos";   # US with dead keys  →  è à ù ì ò …
    # keyMap = "it";         # Italian
  };

  users.users.demon0 = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  system.stateVersion = "25.11";
}