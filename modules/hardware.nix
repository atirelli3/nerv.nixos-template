{ config, lib, pkgs, ... }:

{
  # Load firmware blobs for Wi-Fi cards, GPUs, and other peripherals.
  # Requires nixpkgs.config.allowUnfree = true (set in nix.nix).
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true; # Helps with compatibility

  # AMD CPU microcode updates — applied early in boot via initrd.
  hardware.cpu.amd.updateMicrocode = true;

  # Firmware updates for supported devices (laptops, drives, peripherals) via LVFS.
  # Run updates with: fwupdmgr refresh && fwupdmgr upgrade
  services.fwupd.enable = true;

  # Periodic SSD TRIM to maintain performance and longevity on SSDs.
  # LUKS with allowDiscards = true (set in configuration.nix) is required for TRIM on encrypted drives.
  services.fstrim = {
    enable   = true;
    interval = "weekly";
  };
}
