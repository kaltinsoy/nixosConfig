{ pkgs, spicetify-nix, lib, ... }:

let
  spicePkgs = spicetify-nix.legacyPackages.${pkgs.system};
in
{
  # ── Spicetify — themed Spotify client ─────────────────────────────────
  programs.spicetify = {
    enable = true;

    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha";

    enabledExtensions = with spicePkgs.extensions; [
      adblock               # block ads
      shuffle               # better shuffle
      playlistIcons         # custom playlist icons
      fullAppDisplay        # full-screen now playing
      historyShortcut       # browser-style back/forward
      keyboardShortcut      # keyboard shortcuts
      volumePercentage      # show volume %
      popupLyrics           # floating lyrics popup
    ];

    enabledCustomApps = with spicePkgs.apps; [
      newReleases           # new releases page
      lyricsPlus            # enhanced lyrics
    ];
  };
}
