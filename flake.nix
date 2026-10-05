{
  description = "NixOS configuration — cybersec / FPGA / desktop workstation";

  inputs = {
    # ── Core ──────────────────────────────────────────────────────────────
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Hardware ──────────────────────────────────────────────────────────
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Browsers ──────────────────────────────────────────────────────────
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Spotify ───────────────────────────────────────────────────────────
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── NvChad (pinned starter config) ────────────────────────────────────
    nvchad-starter = {
      url = "github:NvChad/starter";
      flake = false;
    };

    # ── Fingerprint reader (Synaptics 06cb:009a) ──────────────────────────
    # Pinned to its internal nixos-24.11 input because python-validity
    # driver requires Python 3.12 setuptools packaging.
    nixos-06cb-009a-fingerprint-sensor = {
      url = "github:ahbnr/nixos-06cb-009a-fingerprint-sensor";
    };

    # ── Antigravity IDE ───────────────────────────────────────────────────
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Claude Desktop ────────────────────────────────────────────────────
    claude-desktop = {
      url = "github:poeck/claude-desktop-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── ZapFast (native WhatsApp client, built from source) ───────────────
    zapfast = {
      url = "github:crmne/zapfast";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Spotifast (native Spotify client) ─────────────────────────────────
    # nixpkgs-unstable lags upstream (0.10.1 vs 0.12.0), so build from the release tag.
    # Bump the tag to update: `nix flake lock --override-input spotifast github:crmne/spotifast/vX.Y.Z`
    spotifast = {
      url = "github:crmne/spotifast/v0.12.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "zapfast/rust-overlay";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, zen-browser, spicetify-nix, nvchad-starter, nixos-06cb-009a-fingerprint-sensor, antigravity-nix, claude-desktop, ... } @ inputs:
    let
      system = "x86_64-linux";
      pkgs   = nixpkgs.legacyPackages.${system};

      # ── Change these to match your machine ────────────────────────────
      hostname = "sumatra";
      username = "koray";           # ← your username
      # ──────────────────────────────────────────────────────────────────
    in
    {
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs username hostname; };

        modules = [
          # ThinkPad T480s hardware preset (Intel 8th-gen, single battery, WWAN slot)
          nixos-hardware.nixosModules.lenovo-thinkpad-t480s

          # Synaptics 06cb:009a Match-on-Host fingerprint reader module
          nixos-06cb-009a-fingerprint-sensor.nixosModules."06cb-009a-fingerprint-sensor"

          claude-desktop.nixosModules.default

          ./hosts/default/configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs       = true;
              useUserPackages     = true;
              backupFileExtension = "backup";
              extraSpecialArgs = {
                inherit inputs username spicetify-nix zen-browser nvchad-starter antigravity-nix claude-desktop;
              };
              users.${username} = import ./home/home.nix;
            };
          }
        ];
      };
    };
}
