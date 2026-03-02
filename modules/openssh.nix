{ config, lib, pkgs, ... }:

{
  services.openssh = {
    enable = true;  # Enable the OpenSSH daemon.
    settings.PermitRootLogin = "no";
  };
}
