{ config, lib, pkgs, ... }:

{
  # SSH daemon on a non-standard port so port 22 is free for the tarpit (endlessh).
  # Connect with: ssh -p 2222 myUser@host
  services.openssh = {
    enable = true;
    ports = [ 2222 ];
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ "myUser" ]; # replace with your actual username
    };
  };

  # Declarative authorized keys — replace "myUser" and add your public key(s).
  #
  # Option A: inline the key directly
  #   users.users."myUser".openssh.authorizedKeys.keys = [
  #     "ssh-ed25519 AAAA... user@host"
  #   ];
  #
  # Option B: point to an authorized_keys file (e.g. ./ssh/authorized_keys)
  #   users.users."myUser".openssh.authorizedKeys.keyFiles = [
  #     ./ssh/authorized_keys
  #   ];
  #
  # Key generation (run once outside Nix, then paste the public key above):
  #   ssh-keygen -t ed25519 -C "user@host" -f ~/.ssh/id_ed25519

  # Tarpit on port 22: sends an infinitely slow SSH banner to waste bot connections.
  # Attackers that target the default port get stuck here; real users connect on 2222.
  services.endlessh = {
    enable = true;
    port = 22;
    openFirewall = true;
  };

  # Rate-limits and bans offending IPs. NixOS auto-enables a pre-configured SSH jail.
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      # Private subnets — never ban your own LAN.
      "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16"
    ];
    bantime = "24h";
    bantime-increment = {
      enable = true; # Exponentially lengthen ban on repeat offenders.
      # Only formula or multiplier, mutal exclusive
      # formula = "ban.Time * math.exp(float(ban.Count + 1) * banFactor) / math.exp(1 * banFactor)";
      # multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h"; # Cap at 1 week.
      overalljails = true; # Aggregate violations across all jails.
    };
    jails = {
      # Tighten the built-in SSH jail: aggressive mode also catches probes for
      # invalid users and non-existent home directories (typical scanner patterns).
      sshd.settings = {
        mode = "aggressive";
        maxretry = 3;    # Ban after 3 failures (overrides global 5).
        findtime = 600;  # Within a 10-minute window.
        port = "2222";   # Point to the actual SSH port, not 22.
      };
    };
  };
}
