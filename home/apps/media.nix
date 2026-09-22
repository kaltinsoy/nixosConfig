{ pkgs, lib, ... }:

{
  # ── Spotify & Media ───────────────────────────────────────────────────
  # Official Spotify client without third-party theme/wrapper modifications
  home.packages = with pkgs; [
    spotify
  ];
}

