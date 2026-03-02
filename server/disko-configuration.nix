{
  disko.devices = {
    disk.main = {
      device = "/dev/DISK";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {  # BOOT ??
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
              extraArgs = [ "-n" "NIXBOOT" ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              settings.allowDiscards = true;
              extraFormatArgs = [ "--label" "NIKLUKS" ];
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
        swap = {
          size = "SIZE_RAM * 2";
          content = {
            type = "swap";
            extraArgs = [ "-L" "NIXSWAP" ];
          };
        };
        store = {
          size = "SIZE";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/nix";
            extraArgs = [ "-L" "NIXSTORE" ];
          };
        };
        persist = {
          size = "SIZE";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/persist";
            extraArgs = [ "-L" "NIXPERSIST" ];
          };
        };
        root = {  # I really need it with tmpfs ??
          size = "SIZE";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            extraArgs = [ "-L" "NIXROOT" ];
          };
        };
        home = {
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