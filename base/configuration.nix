{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/secureboot.nix
    ./modules/zsh.nix
    ./modules/openssh.nix
  ];

  # Define your hostname.
  networking.hostName = "nixos-base";
  networking.networkmanager.enable = true;

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

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;  # Use latest kernel.
    initrd = {
      systemd.enable   = true;   # required for services.lvm and crypttabExtraOpts
      services.lvm.enable = true;
      kernelModules = [ "dm-snapshot" "cryptd" ];
      luks.devices."cryptroot" = {
        device = "/dev/disk/by-label/NIXLUKS";  # Define our LUKS device
        preLVM = true;
        allowDiscards = true;
      };
    };
    loader = {
      systemd-boot.enable = true;  # Use the systemd-boot EFI boot loader.
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
    extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
  };



  system.stateVersion = "25.11";
}