{ pkgs, lib, ... }:

{
  # ── Steam & Gaming ────────────────────────────────────────────────────
  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
    package = pkgs.steam.override {
      extraEnv = {
        STEAM_FORCE_DESKTOPUI_SCALING = "1.25";
        XCURSOR_SIZE                  = "48";
        XCURSOR_THEME                 = "Adwaita";
      };
    };
    remotePlay.openFirewall = true;                 # Open ports for Steam Remote Play
    localNetworkGameTransfers.openFirewall = true;  # Open ports for Steam Local Network Game Transfers
    protontricks.enable = true;                     # Helper for Proton prefix management
    gamescopeSession.enable = true;                 # Gamescope micro-compositor session
  };

  # Feral Interactive GameMode for system optimizations during gaming
  programs.gamemode.enable = true;

  # Gaming utilities (ProtonUp-Qt for managing Proton/Wine versions)
  environment.systemPackages = with pkgs; [
    protonup-qt
  ];
}
