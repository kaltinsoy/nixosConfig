{ inputs, zen-browser, pkgs, ... }:

let
  system = "x86_64-linux";
in
{
  home.packages = [
    # ── Zen Browser ───────────────────────────────────────────────────
    zen-browser.packages.${system}.default

    # ── Firefox (fallback / Tor Browser safe alternative) ─────────────
    pkgs.firefox
    pkgs.tor-browser   # was tor-browser-bundle-bin
  ];

  # ── Firefox hardened profile (via programs.firefox) ───────────────────
  programs.firefox = {
    enable = true;
    profiles.default = {
      isDefault = true;
      settings = {
        # Privacy
        "browser.contentblocking.category"     = "strict";
        "privacy.donottrackheader.enabled"      = true;
        "privacy.trackingprotection.enabled"    = true;
        "network.dns.disablePrefetch"           = true;
        "browser.send_pings"                    = false;
        "geo.enabled"                           = false;
        "browser.sessionstore.privacy_level"    = 2;
        # WebRTC (leak prevention)
        "media.peerconnection.enabled"          = false;
        # Telemetry off
        "toolkit.telemetry.enabled"             = false;
        "datareporting.healthreport.uploadEnabled" = false;
        # UI
        "browser.uidensity"                     = 1;
        "browser.compactmode.show"              = true;
      };
    };
  };
}
