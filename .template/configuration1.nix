# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];  # Enable Flakes
  nixpkgs.config.allowUnfree = true;  # Allow Unfree packages

  boot = {
    initrd = {
      kernelModules = [ "dm-snapshot" "cryptd" ];
      services.lvm.enable = true;
      systemd.enable = true;
      luks.devices."cryptroot" = {
        device = "/dev/disk/by-label/NIXLUKS";
        preLVM = true;
        allowDiscards = true;
        crypttabExtraOpts = [ "tpm2-device=auto" "tpm2-pcrs=0+7" ];
      };
    };
    loader = {
      systemd-boot.enable = lib.mkForce false;  # Use the systemd-boot EFI boot loader.
      efi.canTouchEfiVariables = true;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXROOT";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-label/NIXSWAP"; }
  ];

  hardware = {
    enableAllFirmware = true;  # Helps with compatibility
    bluetooth = {
      enable = true;  # Enable bluetooth.
      powerOnBoot = true;
    };
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    # Configure network proxy if necessary
    # proxy = {
    #   default = "http://user:password@proxy:port/";
    #   noProxy = "127.0.0.1,localhost,internal.domain";
    # };
    # Open ports in the firewall.
    # firewall = {
    #   enable = false;
    #   allowedTCPPorts = [ ... ];
    #   allowedUDPPorts = [ ... ];
    # };
  };

  security.rtkit.enable = true;
  security = {
    protectKernelImage = true;      # impedisce sostituzione kernel a runtime
    forcePageTableIsolation = true; # protezione Meltdown/Spectre
    sudo.execWheelOnly = true;
    auditd.enable = true;
    audit = {
      enable = true;
      rules = [
        "-a exit,always -F arch=b64 -S execve"  # logga tutti i processi
        "-a exit,always -F arch=b64 -S openat"  # logga tutti i file aperti
        "-w /etc/passwd -p wa"                  # modifica a passwd
        "-w /etc/shadow -p wa"                  # modifica a shadow
      ];
    };
    tpm2 = {
      enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };
  };

  time.timeZone = "Europe/Rome";  # Set your time zone.

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;  # use xkb.options in tty.
  };

  environment.systemPackages = with pkgs; [
    sbctl
    tpm2-tss
    tpm2-tools
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.demon0 = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
      vim
      wget
      ungoogled-chromium
    ];
  };

  # Default shell => ZSH
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  services = {
    xserver = {
      enable = false;
      xkb = {
        layout = "us";
        variant = "intl";
        options = "eurosign:e,caps:escape";
      };
    };
    printing.enable = true;  # Enable CUPS to print documents.
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
	  # If you want to use JACK applications, uncomment this
	  # jack.enable = true;
	  };
	  libinput.enable = false;  # Enable touchpad support (enabled default in most desktopManager).

	  openssh = {
	    enable = true;  # Enable the OpenSSH daemon.
	    settings.PermitRootLogin = "no";
	  };
  };



  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true; - is not supported with flakes

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?
}
