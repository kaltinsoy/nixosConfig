{ lib, ... }:

# GNOME extension settings via dconf
# Lightweight, high-performance configuration without heavy shaders or blur.

{
  dconf.settings = {
    # ── Enable extensions list ─────────────────────────────────────────
    "org/gnome/shell" = {
      enabled-extensions = [
        "dash-to-dock@micxgx.gmail.com"
        "appindicatorsupport@rgcjonas.gmail.com"
        "caffeine@patapon.info"
        "clipboard-indicator@tudmotu.com"
        "just-perfection-desktop@just-perfection"
        "Vitals@CoreCoding.com"
        "grand-theft-focus@zalckos.github.com"
      ];
      favorite-apps = [
        "zen-browser.desktop"
        "org.gnome.Nautilus.desktop"
        "dev.zed.Zed.desktop"
        "virt-manager.desktop"
        "org.gnome.Terminal.desktop"
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
      dock-position            = "LEFT";
      dock-fixed               = true;
      extend-height            = true;
      icon-size-fixed          = true;
      dash-max-icon-size       = 40;
      show-trash               = false;
      show-mounts              = false;
      running-indicator-style  = "DOTS";
      transparency-mode        = "FIXED";
      background-opacity       = 0.85;
      custom-theme-shrink      = true;
      scroll-action            = "cycle-windows";
    };

    # ── Caffeine ──────────────────────────────────────────────────────
    "org/gnome/shell/extensions/caffeine" = {
      indicator-position = 0;
      user-enabled       = false;
    };

    # ── Just Perfection ────────────────────────────────────────────────
    "org/gnome/shell/extensions/just-perfection" = {
      activities-button = false;
      app-menu          = false;
      search            = true;
      workspace-switcher-should-show = true;
      animation         = 2;
    };

    # ── Vitals ────────────────────────────────────────────────────────
    "org/gnome/shell/extensions/vitals" = {
      hot-sensors      = [ "_processor_usage_" "_memory_usage_" "__network-rx_max__" ];
      show-temperature = true;
      show-voltage     = false;
      show-fan         = true;
      show-memory      = true;
      show-processor   = true;
      show-network     = true;
      show-storage     = false;
      position-in-panel = 0;
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
