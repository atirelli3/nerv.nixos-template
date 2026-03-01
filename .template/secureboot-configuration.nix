# secureboot-configuration.nix

{ config, lib, pkgs, ... }:

let
  luks-cryptenroll = pkgs.writeTextFile {
    name = "luks-cryptenroll";
    destination = "/bin/luks-cryptenroll";
    executable = true;

    # Note: You can hardcode additional LUKS devices like so:
    # text = let
    #   ...
    #   luksDevice02 = "BEEGLUKS01";
    #   luksDevice03 = "BEEGLUKS02";
    # in ''
    #   ...
    #   sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=0+7 /dev/disk/by-label/${luksDevice02}
    #   sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=0+7 /dev/disk/by-label/${luksDevice03}
    # '';

    text = let
      luksDevice01 = "NIXLUKS";
    in ''
      sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=0+7 /dev/disk/by-label/${luksDevice01}
    '';
  };
in

{
  environment.systemPackages = [
    luks-cryptenroll
    # For debugging and troubleshooting Secure Boot.
    pkgs.sbctl
    # Needed to use the TPM2 chip with `systemd-cryptenroll`
    pkgs.tpm2-tss
    pkgs.tpm2-tools
  ];

  # Lanzaboote currently replaces the systemd-boot module.
  # This setting is usually set to true in configuration.nix
  # generated at installation time. So we force it to false
  # for now.
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  systemd.services.secureboot-setup = {
    description = "First boot: enroll sbctl keys and TPM2";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    path = [ pkgs.sbctl pkgs.systemd pkgs.tpm2-tss ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
    };
    script = ''
      if ! sbctl status | grep -q "Setup Mode.*Enabled"; then
        echo "Not in setup mode, skipping"
        exit 0
      fi
      sbctl enroll-keys --microsoft
      sleep 2
      if ! systemd-cryptenroll /dev/disk/by-label/NIXLUKS | grep -q "tpm2"; then
        systemd-cryptenroll \
          --wipe-slot=tpm2 \
          --tpm2-device=auto \
          --tpm2-pcrs=0+7 \
          /dev/disk/by-label/NIXLUKS
      fi
      systemctl disable secureboot-setup
    '';
  };
}