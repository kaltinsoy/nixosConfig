{ inputs, username, hostname, pkgs, lib, config, ... }:

{
  imports = [
    ./hardware-configuration.nix   # Replace with: nixos-generate-config output

    ../../modules/system/boot.nix
    ../../modules/system/networking.nix
    ../../modules/system/locale.nix
    ../../modules/system/security.nix
    ../../modules/system/services.nix

    ../../modules/desktop/gnome.nix
    ../../modules/desktop/fonts.nix

    ../../modules/hardware/lenovo.nix

    ../../modules/virt/qemu-kvm.nix
    ../../modules/fpga/fpga.nix
    ../../modules/security-tools/cybersec.nix
  ];

  # ── Nix daemon settings ───────────────────────────────────────────────
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store   = true;
      trusted-users         = [ "root" username ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkQ5JKhCXymAd0EvKBOSE="
      ];
    };
    gc = {
      automatic = true;
      dates     = "weekly";
      options   = "--delete-older-than 14d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  # ── User account ──────────────────────────────────────────────────────
  users.users.${username} = {
    isNormalUser = true;
    description  = username;
    shell        = pkgs.bash;
    extraGroups  = [
      "wheel"         # sudo
      "networkmanager"
      "libvirtd"      # QEMU/KVM
      "kvm"
      "wireshark"     # capture without root
      "docker"
      "dialout"       # USB/JTAG serial
      "plugdev"       # USB devices (openFPGALoader, Gowin)
      "video"         # backlight control via `light`
      "input"         # fingerprint reader udev access
    ];
  };

  # ── Essential system packages ─────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Dev essentials
    git git-lfs curl wget unzip p7zip
    htop btop neofetch fastfetch
    file tree fd ripgrep bat eza delta
    jq yq-go moreutils

    # Build tooling
    gcc gnumake cmake pkg-config ninja meson
    python3 python3Packages.pip

    # Nix tooling
    nil nixfmt-rfc-style nix-tree nix-diff
    nix-output-monitor nvd

    # Terminal multiplexer
    tmux zellij

    # Archive
    zip unzip xz gzip bzip2 zstd

    # System info
    lshw inxi pciutils usbutils dmidecode
  ];

  system.stateVersion = "25.05";
}
