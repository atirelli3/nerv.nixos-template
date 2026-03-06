{ config, lib, pkgs, ... }:

{
  # CUPS printing daemon.
  services.printing = {
    enable = true;
    # Add drivers for your printer brand. Common options:
    #   pkgs.gutenprint      — broad multi-brand support
    #   pkgs.gutenprintBin   — binary drivers for some Epson/Canon models
    #   pkgs.hplip           — HP printers
    #   pkgs.brlaser         — Brother laser printers
    drivers = with pkgs; [
      gutenprint
    ];
  };

  # Network printer discovery via mDNS (.local hostnames).
  # avahi.enable is already set in pipewire.nix; nssmdns4 adds printer resolution.
  services.avahi.nssmdns4 = true;

  # Declarative printer definition (optional — remove if you prefer CUPS web UI).
  # After adding, apply with: nixos-rebuild switch, then cups will have it pre-configured.
  # hardware.printers.ensurePrinters = [{
  #   name        = "MyPrinter";
  #   location    = "Home";
  #   deviceUri   = "ipp://printer.local/ipp/print"; # or usb://... for USB
  #   model       = "drv:///sample.drv/generic.ppd"; # or path to PPD file
  #   ppdOptions.PageSize = "A4";
  # }];
  # hardware.printers.ensureDefaultPrinter = "MyPrinter";
}
