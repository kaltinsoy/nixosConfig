{ inputs, pkgs, lib, ... }:

{
  # ── Spotify & Media ───────────────────────────────────────────────────
  # Official Spotify client without third-party theme/wrapper modifications
  home.packages = [
    pkgs.spotify
    inputs.spotifast.packages.${pkgs.stdenv.hostPlatform.system}.default # native Rust Spotify client (no autostart)
  ];
}

