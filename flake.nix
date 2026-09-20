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
    nixos-hardware.url = "github:NixOS/nixos-hardware";

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
    nixos-06cb-009a-fingerprint-sensor = {
      url = "github:ahbnr/nixos-06cb-009a-fingerprint-sensor";
    };

    # ── Antigravity IDE ───────────────────────────────────────────────────
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, zen-browser, spicetify-nix, nvchad-starter, nixos-06cb-009a-fingerprint-sensor, antigravity-nix, ... } @ inputs:
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
          # ThinkPad T480s hardware preset (Intel 8th-gen, dual battery, WWAN slot)
          nixos-hardware.nixosModules.lenovo-thinkpad-t480s

          # Synaptics 06cb:009a Match-on-Host fingerprint reader module
          nixos-06cb-009a-fingerprint-sensor.nixosModules."06cb-009a-fingerprint-sensor"

          ./hosts/default/configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs       = true;
              useUserPackages     = true;
              backupFileExtension = "backup";
              extraSpecialArgs = {
                inherit inputs username spicetify-nix zen-browser nvchad-starter antigravity-nix;
              };
              users.${username} = import ./home/home.nix;
            };
          }
        ];
      };
    };
}
