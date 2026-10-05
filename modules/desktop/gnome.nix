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
    QT_QPA_PLATFORM    = "wayland;xcb";
    SDL_VIDEODRIVER    = "wayland";
  };

  # ── GNOME packages ────────────────────────────────────────────────────
  # NOTE: in nixpkgs-unstable the gnome.* namespace was removed;
  #       packages are now at the top level (e.g. pkgs.nautilus).
  environment.systemPackages = with pkgs; [
    # Core GNOME extras & icons
    gnome-tweaks
    gnome-extension-manager
    dconf-editor
    adwaita-icon-theme
    hicolor-icon-theme

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

    # GNOME Shell extensions
    gnomeExtensions.dash-to-dock
    gnomeExtensions.appindicator
    gnomeExtensions.caffeine
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.just-perfection
    gnomeExtensions.vitals
    gnomeExtensions.grand-theft-focus
    gnomeExtensions.blur-my-shell
    gnomeExtensions.brightness-control-using-ddcutil

    # External monitor brightness over DDC/CI (CLI + used by the extension)
    ddcutil

    # The brightness extension probes every monitor with parallel ddcutil
    # processes, and ddcutil randomly answers "No monitor detected" for one of
    # them. Serialising the calls behind a lock makes detection reliable.
    (writeShellScriptBin "ddcutil-serial" ''
      exec ${util-linux}/bin/flock -w 30 "''${XDG_RUNTIME_DIR:-/tmp}/ddcutil.lock" ${ddcutil}/bin/ddcutil "$@"
    '')
  ];

  # ── External monitor brightness (DDC/CI) ──────────────────────────────
  # Loads i2c-dev and grants the "i2c" group access to /dev/i2c-*, so ddcutil
  # can reach the monitors (user is added to "i2c" in configuration.nix).
  hardware.i2c.enable = true;

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
