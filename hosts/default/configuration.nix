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
    ../../modules/desktop/steam.nix

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
      options   = "--delete-older-than 7d";
    };
  };

  # ── Shell Aliases ─────────────────────────────────────────────────────
  environment.shellAliases = {
    nrs = "sudo nixos-rebuild switch --flake /home/koray/nixos-config#sumatra";
    nrb = "sudo nixos-rebuild boot --flake /home/koray/nixos-config#sumatra";
    nrt = "sudo nixos-rebuild test --flake /home/koray/nixos-config#sumatra";
    nclean = "nclean";
    ncg = "nclean";
  };

  # ── Prune old NixOS system generations (keep last 3) ──────────────────
  systemd.services.nix-prune-generations = {
    description = "Prune old NixOS system generations (keep last 3)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.nix}/bin/nix-env --profile /nix/var/nix/profiles/system --delete-generations +3";
    };
  };
  systemd.timers.nix-prune-generations = {
    description = "Timer to prune old NixOS system generations";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
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
      "docker"
      "dialout"       # USB/JTAG serial
      "plugdev"       # USB devices (openFPGALoader, Gowin)
      "video"         # backlight control via brightnessctl
      "input"         # fingerprint reader udev access
    ];
  };

  # ── Essential system packages ─────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Dev essentials
    git git-lfs curl wget unzip p7zip
    htop btop fastfetch
    file tree fd ripgrep bat eza delta
    jq yq-go moreutils

    # Build tooling
    gcc gnumake cmake pkg-config ninja meson
    python3 python3Packages.pip

    # Nix tooling & rebuild scripts
    nil nixfmt nix-tree nix-diff
    nix-output-monitor nvd
    (writeShellScriptBin "nrs" ''exec sudo nixos-rebuild switch --flake /home/koray/nixos-config#sumatra "$@"'')
    (writeShellScriptBin "nrb" ''exec sudo nixos-rebuild boot --flake /home/koray/nixos-config#sumatra "$@"'')
    (writeShellScriptBin "nrt" ''exec sudo nixos-rebuild test --flake /home/koray/nixos-config#sumatra "$@"'')
    (writeShellScriptBin "nclean" ''
      set -e
      echo ":: [1/4] Removing obsolete user profile generations..."
      nix-collect-garbage -d "$@"
      echo ":: [2/4] Removing obsolete system generations..."
      sudo nix-collect-garbage -d "$@"
      echo ":: [3/4] Updating bootloader entries..."
      sudo /run/current-system/bin/switch-to-configuration boot
      echo ":: [4/4] Optimising nix store (hardlinking duplicate files)..."
      nix store optimise
      echo ":: Cleanup complete!"
    '')
    (writeShellScriptBin "ncg" ''exec nclean "$@"'')

    # Terminal multiplexer
    tmux zellij

    # Archive
    zip unzip xz gzip bzip2 zstd

    # System info
    lshw inxi pciutils usbutils dmidecode
  ];

  system.stateVersion = "25.05";
}
