# configuration.nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # ============================================================
  # NIX
  # ============================================================
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    allowed-users = [ "@wheel" ];
    trusted-users = [ "root" ];
    auto-optimise-store = true;
  };
  nixpkgs.config.allowUnfree = true;

  # ============================================================
  # BOOT — LUKS + LVM + Lanzaboote (Secure Boot)
  # ============================================================
  boot = {
    initrd = {
      availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
      kernelModules = [ "dm-snapshot" "cryptd" "virtio_blk" "virtio_pci" ];
      services.lvm.enable = true;
      systemd.enable = true;
      luks.devices."cryptroot" = {
        device = "/dev/disk/by-label/NIXLUKS";
        allowDiscards = true;
        crypttabExtraOpts = [ "tpm2-device=auto" "tpm2-pcrs=0+7" ];
      };
    };

    loader = {
      systemd-boot.enable = lib.mkForce false; # sostituito da lanzaboote
      systemd-boot.configurationLimit = 10;
      efi.canTouchEfiVariables = true;
    };

    lanzaboote = {
      enable = true;
      pkiBundle = "/persist/var/lib/sbctl"; # in persist perché sbctl deve sopravvivere al reboot
    };

    # Kernel hardening
    kernelParams = [
      "amd_iommu=on"         # IOMMU per VM e analisi malware
      "iommu=pt"             # pass-through mode
      "slab_nomerge"         # previene exploit heap
      "init_on_alloc=1"      # azzera memoria allocata
      "init_on_free=1"       # azzera memoria liberata
      "page_alloc.shuffle=1" # randomizza allocazione pagine
      "pti=on"               # Page Table Isolation (Meltdown)
      "vsyscall=none"        # disabilita vsyscall legacy
      "debugfs=off"          # disabilita debugfs
    ];

    kernel.sysctl = {
      # Rete - anti spoofing e protezioni
      "net.ipv4.conf.all.rp_filter"           = 1;
      "net.ipv4.conf.default.rp_filter"       = 1;
      "net.ipv4.tcp_syncookies"               = 1;
      "net.ipv4.conf.all.accept_redirects"    = 0;
      "net.ipv4.conf.all.send_redirects"      = 0;
      "net.ipv6.conf.all.accept_redirects"    = 0;
      "net.ipv4.conf.all.accept_source_route" = 0;
      # Kernel
      "kernel.dmesg_restrict"           = 1; # solo root legge dmesg
      "kernel.kptr_restrict"            = 2; # nasconde kernel pointers
      "kernel.unprivileged_bpf_disabled"= 1; # eBPF solo root
      "net.core.bpf_jit_harden"         = 2; # hardening JIT eBPF
      "kernel.yama.ptrace_scope"        = 1; # 1 e non 2 per debug/pentesting
      "kernel.perf_event_paranoid"      = 3;
      # Memoria - max ASLR entropy
      "vm.mmap_rnd_bits"       = 32;
      "vm.mmap_rnd_compat_bits"= 16;
    };
  };

  # ============================================================
  # FILESYSTEM — tmpfs root + persist
  # ============================================================
  fileSystems = {
    # Root in tmpfs — sparisce ad ogni reboot
    "/" = lib.mkForce {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=8G" "mode=755" ];
    };

    "/boot" = lib.mkForce {
      device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

    # Nix store — sempre su disco, immutabile
    "/nix" = lib.mkForce {
      device = "/dev/disk/by-label/NIXSTORE";
      fsType = "ext4";
      neededForBoot = true;
    };

    # Dati persistenti — tutto ciò che sopravvive al reboot
    "/persist" = lib.mkForce {
      device = "/dev/disk/by-label/NIXPERSIST";
      fsType = "ext4";
      neededForBoot = true;
    };

    "/home" = lib.mkForce {
      device = "/dev/disk/by-label/NIXHOME";
      fsType = "ext4";
      neededForBoot = true;
    };
  };

  # swapDevices = [{
  #   device = "/dev/disk/by-label/NIXSWAP";
  #   randomEncryption.enable = true; # cifratura random ad ogni boot
  # }];
  
  swapDevices = [{
    device = "/dev/disk/by-partuuid/5d5825bc-603b-487d-9d11-5965fbbaaaf4";
    randomEncryption.enable = true; # cifratura random ad ogni boot
  }];

  # ============================================================
  # IMPERMANENCE — cosa sopravvive al reboot
  # ============================================================
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      # Secure Boot — CRITICO, senza questo perdi le chiavi ad ogni reboot
      "/var/lib/sbctl"
      # Sistema
      "/var/lib/nixos"
      "/var/log"
      "/var/lib/NetworkManager"  # connessioni WiFi salvate
      # Virtualizzazione e container
      "/var/lib/docker"
      "/var/lib/libvirt"
      # Nixos config
      "/etc/nixos"
    ];
    files = [
      "/etc/machine-id"              # ID macchina stabile
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_rsa_key"
    ];
  };

  # Impermanence per la home utente
  users.users.demon0.home = "/home/demon0";
  environment.persistence."/persist".users.demon0 = {
    directories = [
      "dev"              # codice e progetti
      "documents"        # documenti
      ".ssh"             # chiavi SSH
      ".gnupg"           # chiavi GPG
      ".local/share"     # dati applicazioni
    ];
  };

  # ============================================================
  # HARDWARE
  # ============================================================
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # ============================================================
  # NETWORKING
  # ============================================================
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
      logRefusedConnections = true;
    };
  };

  # ============================================================
  # SECURITY
  # ============================================================
  security = {
    rtkit.enable = true;
    protectKernelImage = true;       # impedisce sostituzione kernel a runtime
    forcePageTableIsolation = true;  # protezione Meltdown/Spectre
    sudo.execWheelOnly = true;
    auditd.enable = true;
    audit = {
      enable = true;
      rules = [
        "-a exit,always -F arch=b64 -S execve"  # logga tutti i processi
        "-a exit,always -F arch=b64 -S openat"  # logga tutti i file aperti
        "-w /etc/passwd -p wa"                   # modifica a passwd
        "-w /etc/shadow -p wa"                   # modifica a shadow
      ];
    };
    tpm2 = {
      enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };
  };

  # ============================================================
  # SECUREBOOT — script post-install automatico
  # ============================================================
  systemd.services.secureboot-setup = {
    description = "First boot: enroll sbctl keys and TPM2 LUKS";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    path = [ pkgs.sbctl pkgs.systemd pkgs.tpm2-tss ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
    };
    script = ''
      # Flag file — se esiste il setup è già stato eseguito
      if [ -f /persist/var/lib/secureboot-setup-done ]; then
        echo "Secure boot setup already completed, skipping"
        exit 0
      fi

      # Controlla setup mode — se non siamo in setup mode esci
      if ! ${pkgs.sbctl}/bin/sbctl status | grep -q "Setup Mode.*Enabled"; then
        echo "Not in setup mode, skipping key enrollment"
        exit 0
      fi

      echo "Enrolling secure boot keys..."
      ${pkgs.sbctl}/bin/sbctl enroll-keys --microsoft

      sleep 2

      echo "Enrolling TPM2 LUKS key..."
      if ! ${pkgs.systemd}/bin/systemd-cryptenroll /dev/disk/by-label/NIXLUKS | grep -q "tpm2"; then
        ${pkgs.systemd}/bin/systemd-cryptenroll \
          --wipe-slot=tpm2 \
          --tpm2-device=auto \
          --tpm2-pcrs=0+7 \
          /dev/disk/by-label/NIXLUKS
      else
        echo "TPM2 already enrolled, skipping"
      fi

      # Crea flag file in persist — sopravvive ai reboot
      touch /persist/var/lib/secureboot-setup-done
      echo "Secure boot setup completed successfully"
    '';
  };

  # ============================================================
  # LOCALE
  # ============================================================
  time.timeZone = "Europe/Rome";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };
  services.xserver = {
    enable = false;
    xkb = {
      layout = "us";
      variant = "intl";
      options = "eurosign:e,caps:escape";
    };
  };

  # ============================================================
  # UTENTI
  # ============================================================
  users = {
    mutableUsers = false; # utenti immutabili — definiti solo qui
    defaultUserShell = pkgs.zsh;
    users.demon0 = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
      # password gestita con hashedPassword o passwordFile
      # genera con: mkpasswd -m sha-512
      hashedPasswordFile = "/persist/passwords/demon0";
      packages = with pkgs; [
        tree
        vim
        wget
        ungoogled-chromium
      ];
    };
  };

  programs.zsh.enable = true;

  # ============================================================
  # SERVIZI
  # ============================================================
  services = {
    fwupd.enable = true;
    fstrim.enable = true;
    printing.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
    libinput.enable = false;
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        X11Forwarding = false;
      };
    };
  };

  # ============================================================
  # PACCHETTI DI SISTEMA
  # ============================================================
  environment.systemPackages = with pkgs; [
    # Secure Boot / TPM2
    sbctl
    tpm2-tss
    tpm2-tools
    # Utils base
    tree
    vim
    wget
  ];

  # ============================================================
  # AGGIORNAMENTI & MANUTENZIONE
  # ============================================================
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    flake = "/etc/nixos#nixos";
    dates = "daily";
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 20d";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  # ============================================================
  system.stateVersion = "25.11";
}