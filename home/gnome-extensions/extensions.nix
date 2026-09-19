{ lib, ... }:

# GNOME extension settings via dconf
# Lightweight, high-performance configuration without heavy shaders or blur.

{
  dconf.settings = {
    # ── Enable extensions list ─────────────────────────────────────────
    "org/gnome/shell" = {
      enabled-extensions = [
        "blur-my-shell@aunetx"
        "dash-to-dock@micxgx.gmail.com"
        "appindicatorsupport@rgcjonas.gmail.com"
        "caffeine@patapon.info"
        "clipboard-indicator@tudmotu.com"
        "Vitals@CoreCoding.com"
        "forge@jmmaranan.com"
        "grand-theft-focus@zalckos.github.com"
        "just-perfection-desktop@just-perfection"
      ];
      disabled-extensions = [
        "pop-shell@system76.com"
        "gsconnect@andyholmes.github.io"
        "nightthemeswitcher@romainvigier.fr"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "rounded-window-corners@fxgn"
      ];
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "org.gnome.Console.desktop"
        "zen-beta.desktop"
      ];
    };

    # ── GNOME Interface (Default Themes) ───────────────────────────────
    "org/gnome/desktop/interface" = {
      color-scheme        = "prefer-dark";
      gtk-theme           = "Adwaita";
      icon-theme          = "Adwaita";
      cursor-theme        = "Adwaita";
      cursor-size         = 24;
      font-name           = "Inter 11";
      monospace-font-name = "JetBrainsMono Nerd Font Mono 11";
      document-font-name  = "Source Serif Pro 11";
      enable-animations   = true;
      show-battery-percentage = true;
      clock-show-seconds  = false;
      clock-show-weekday  = true;
    };

    # ── Window manager ─────────────────────────────────────────────────
    "org/gnome/desktop/wm/preferences" = {
      button-layout    = "appmenu:minimize,maximize,close";
      focus-mode       = "click";
      num-workspaces   = 6;
    };

    "org/gnome/desktop/wm/keybindings" = {
      switch-to-workspace-1 = [ "<Super>1" ];
      switch-to-workspace-2 = [ "<Super>2" ];
      switch-to-workspace-3 = [ "<Super>3" ];
      switch-to-workspace-4 = [ "<Super>4" ];
      switch-to-workspace-5 = [ "<Super>5" ];
      switch-to-workspace-6 = [ "<Super>6" ];
    };

    # ── Dash to Dock ───────────────────────────────────────────────────
    "org/gnome/shell/extensions/dash-to-dock" = {
      apply-custom-theme             = true;
      background-opacity             = 0.85;
      custom-theme-shrink            = true;
      dash-max-icon-size             = 48;
      dock-fixed                     = false;
      dock-position                  = "BOTTOM";
      extend-height                  = false;
      height-fraction                = 0.9;
      icon-size-fixed                = true;
      intellihide-mode               = "FOCUS_APPLICATION_WINDOWS";
      preferred-monitor              = -2;
      preferred-monitor-by-connector = "eDP-1";
      preview-size-scale             = 0.0;
      running-indicator-style        = "DEFAULT";
      scroll-action                  = "cycle-windows";
      show-mounts                    = false;
      show-trash                     = false;
      transparency-mode              = "DEFAULT";
      hot-keys                       = false; # Prevent dash-to-dock from intercepting Super double-tap
    };

    # ── AppIndicator ───────────────────────────────────────────────────
    "org/gnome/shell/extensions/appindicator" = {
      icon-brightness = 0.0;
      icon-contrast   = 0.0;
      icon-opacity    = 240;
      icon-saturation = 0.0;
      icon-size       = 0;
    };

    # ── Blur My Shell ──────────────────────────────────────────────────
    "org/gnome/shell/extensions/blur-my-shell" = {
      rounded-blur-found = false;
      settings-version   = 2;
    };
    "org/gnome/shell/extensions/blur-my-shell/appfolder" = {
      brightness = 0.6;
      sigma      = 30;
    };
    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      blur               = true;
      brightness         = 0.6;
      sigma              = 30;
      static-blur        = true;
      style-dash-to-dock = 0;
    };
    "org/gnome/shell/extensions/blur-my-shell/overview" = {
      blur = true;
    };
    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      blur          = true;
      brightness    = 0.6;
      corner-radius = 0;
      sigma         = 30;
    };
    "org/gnome/shell/extensions/blur-my-shell/window-list" = {
      brightness = 0.6;
      sigma      = 30;
    };

    # ── Forge ──────────────────────────────────────────────────────────
    "org/gnome/shell/extensions/forge" = {
      tiling-mode-enabled = false;
    };

    # ── Caffeine ──────────────────────────────────────────────────────
    "org/gnome/shell/extensions/caffeine" = {
      show-indicator         = "always"; # Always show coffee cup icon in panel
      show-toggle            = true;
      show-notifications     = true;
      cli-toggle             = false;
      indicator-position     = 0;
      indicator-position-max = 2;
      user-enabled           = false;
    };

    # ── Just Perfection ────────────────────────────────────────────────
    "org/gnome/shell/extensions/just-perfection" = {
      activities-button              = false;
      animation                      = 2;
      app-menu                       = false;
      search                         = true;
      workspace-switcher-should-show = true;
      double-super-to-appgrid        = true; # Double tap Super to open App Grid
      overlay-key                    = true;
    };

    # ── Mutter ─────────────────────────────────────────────────────────
    "org/gnome/mutter" = {
      overlay-key = "Super_L";
    };

    # ── Vitals ────────────────────────────────────────────────────────
    "org/gnome/shell/extensions/vitals" = {
      hot-sensors       = [ "_processor_usage_" "_system_load_1m_" "_memory_usage_" "__network-rx_max__" ];
      position-in-panel = 0;
      show-fan          = true;
      show-memory       = true;
      show-network      = true;
      show-processor    = true;
      show-system       = true; # Show system load averages
      show-storage      = false;
      show-temperature  = true;
      show-voltage      = false;
    };

    # ── Touchpad ──────────────────────────────────────────────────────
    "org/gnome/desktop/peripherals/touchpad" = {
      tap-to-click     = true;
      natural-scroll   = true;
      two-finger-scrolling-enabled = true;
      speed            = 0.3;
    };

    # ── Power ─────────────────────────────────────────────────────────
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-battery-timeout = 900;
      sleep-inactive-ac-timeout      = 3600;
      power-button-action            = "suspend";
      idle-dim                       = true;
    };

    # ── Privacy ───────────────────────────────────────────────────────
    "org/gnome/desktop/privacy" = {
      disable-camera           = false;
      disable-microphone       = false;
      recent-files-max-age     = 7;
      remove-old-temp-files    = true;
      remove-old-trash-files   = true;
    };

    # ── Keyboard shortcuts ─────────────────────────────────────────────
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name    = "Ghostty Terminal";
      command = "ghostty";
      binding = "<Super>Return";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      name    = "Virt Manager";
      command = "virt-manager";
      binding = "<Super><Shift>v";
    };
  };
}
