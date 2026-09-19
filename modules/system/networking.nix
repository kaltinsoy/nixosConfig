{ pkgs, ... }:

{
  networking = {
    hostName = "nixos";   # override in configuration.nix via hostname var if desired

    networkmanager = {
      enable = true;
      plugins = with pkgs; [
        networkmanager-openvpn
        networkmanager-openconnect
      ];
    };

    # Firewall — open only what you need
    firewall = {
      enable          = true;
      allowedTCPPorts = [ 22 ];   # SSH
      # WireGuard and VPN connections require loose reverse path filtering;
      # strict (1) drops return traffic when routes/gateways change
      checkReversePath = "loose";
    };
  };

  # ── WireGuard kernel module ───────────────────────────────────────────
  boot.kernelModules = [ "wireguard" ];

  # ── WireGuard & Network management tools ──────────────────────────────
  environment.systemPackages = with pkgs; [
    wireguard-tools       # wg, wg-quick (CLI & WireGuard config parsing)
    networkmanagerapplet  # nm-connection-editor (GUI connection & VPN editor)
  ];

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
