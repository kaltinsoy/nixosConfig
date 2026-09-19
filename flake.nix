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
  };

  outputs = { self, nixpkgs, home-manager, nixos-hardware, zen-browser, spicetify-nix, nvchad-starter, ... } @ inputs:
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

          ./hosts/default/configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs   = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs username spicetify-nix zen-browser nvchad-starter;
              };
              users.${username} = import ./home/home.nix;
            };
          }
        ];
      };
    };
}
