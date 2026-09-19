{ pkgs, ... }:

{
  # ── GNOME / GDM (NixOS 24.05+ option paths) ───────────────────────────
  services.xserver.enable = true;   # still needed for xkb / input

  services.displayManager.gdm = {
    enable  = true;
    # wayland = true is the default and cannot be disabled since GNOME 50
  };

  services.desktopManager.gnome.enable = true;

  # ── Wayland environment variables ─────────────────────────────────────
  environment.sessionVariables = {
    NIXOS_OZONE_WL     = "1";   # Electron apps use Wayland
    MOZ_ENABLE_WAYLAND = "1";
    GDK_BACKEND        = "wayland,x11";
    QT_QPA_PLATFORM    = "wayland;xcb";
    SDL_VIDEODRIVER    = "wayland";
    CLUTTER_BACKEND    = "wayland";
  };

  # ── GNOME packages ────────────────────────────────────────────────────
  # NOTE: in nixpkgs-unstable the gnome.* namespace was removed;
  #       packages are now at the top level (e.g. pkgs.nautilus).
  environment.systemPackages = with pkgs; [
    # Core GNOME extras
    gnome-tweaks
    gnome-extension-manager
    dconf-editor

    # System utilities (de-namespaced from pkgs.gnome.*)
    gnome-disk-utility
    nautilus
    gnome-system-monitor
    gnome-calculator
    file-roller
    eog              # image viewer
    evince           # PDF viewer
    gnome-text-editor
    gnome-clocks
    gnome-weather

    # GNOME Shell extensions (lightweight, high-performance)
    gnomeExtensions.dash-to-dock
    gnomeExtensions.appindicator
    gnomeExtensions.caffeine
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.just-perfection
    gnomeExtensions.vitals
    gnomeExtensions.grand-theft-focus
  ];

  # Exclude bloat from GNOME default install
  # (also de-namespaced in nixpkgs-unstable)
  environment.gnome.excludePackages = with pkgs; [
    gnome-music
    gnome-contacts
    gnome-maps
    gnome-tour
    yelp
    epiphany    # GNOME browser
    totem       # video player
  ];

  # ── Programs ──────────────────────────────────────────────────────────
  programs.dconf.enable = true;
}
