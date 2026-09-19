{ pkgs, ... }:

{
  networking = {
    hostName = "nixos";   # override in configuration.nix via hostname var if desired

    networkmanager.enable = true;

    # Firewall — open only what you need
    firewall = {
      enable          = true;
      allowedTCPPorts = [ 22 ];   # SSH
      # allowedUDPPorts = [];
    };

    # Bridge for libvirt (virbr0 is managed by libvirtd; keep this for manual bridges)
    # bridges.br0.interfaces = [ "enp0s31f6" ];
  };

  # SSH daemon (good for remote management / VM access)
  services.openssh = {
    enable        = true;
    openFirewall  = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin        = "no";
      X11Forwarding          = false;
    };
  };

  # mDNS for local hostname resolution (e.g. nixos.local)
  services.avahi = {
    enable   = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
