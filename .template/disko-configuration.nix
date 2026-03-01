# disko-config.nix
{
  disko.devices = {
    disk.main = {
      device = "/dev/vda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {

          # Partizione EFI/boot
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
              extraArgs = [ "-n" "NIXBOOT" ];
            };
          };

          # Partizione LUKS — contiene tutto il resto via LVM
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              settings.allowDiscards = true;
              extraFormatArgs = [ "--label" "NIXLUKS" ];
              passwordFile = "/tmp/luks-password";
              content = {
                type = "lvm_pv";
                vg = "lvmroot";
              };
            };
          };

        };
      };
    };

    lvm_vg.lvmroot = {
      type = "lvm_vg";
      lvs = {

        # Swap — cifrato con chiave random ad ogni boot
        swap = {
          size = "16G";
          content = {
            type = "swap";
            extraArgs = [ "-L" "NIXSWAP" ];
          };
        };

        # Nix store — il nix store è grande, dagli spazio generoso
        # Root (tmpfs) non occupa spazio su disco
        store = {
          size = "40G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/nix";
            extraArgs = [ "-L" "NIXSTORE" ];
          };
        };

        # Persist — tutto ciò che sopravvive ai reboot
        persist = {
          size = "15G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/persist";
            extraArgs = [ "-L" "NIXPERSIST" ];
          };
        };

        # Root — lascia il resto per dati utente e applicazioni
        root = {
          size = "100%FREE";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/home";
            extraArgs = [ "-L" "NIXHOME" ];
          };
        };

      };
    };
  };
}
