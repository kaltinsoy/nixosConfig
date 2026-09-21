{ pkgs, lib, ... }:

{
  # ── Steam & Gaming ────────────────────────────────────────────────────
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;                 # Open ports for Steam Remote Play
    localNetworkGameTransfers.openFirewall = true;  # Open ports for Steam Local Network Game Transfers
    protontricks.enable = true;                     # Helper for Proton prefix management
    gamescopeSession.enable = true;                 # Gamescope micro-compositor session
  };

  # Feral Interactive GameMode for system optimizations during gaming
  programs.gamemode.enable = true;
}
