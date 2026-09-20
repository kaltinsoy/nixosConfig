{ inputs, username, spicetify-nix, zen-browser, nvchad-starter, pkgs, lib, config, ... }:

{
  imports = [
    ./neovim/neovim.nix
    ./apps/browsers.nix
    ./apps/media.nix
    ./gnome-extensions/extensions.nix

    # Spicetify module
    spicetify-nix.homeManagerModules.default
  ];

  home = {
    username    = username;
    homeDirectory = "/home/${username}";
    stateVersion = "25.05";

    # ── Common home packages ──────────────────────────────────────────
    packages = with pkgs; [
      # Dev tools
      gh             # GitHub CLI
      git-credential-oauth
      lazygit
      delta          # better git diff
      difftastic
      pre-commit

      # Terminal emulators
      ghostty        # fast GPU terminal
      alacritty

      # TUI utils
      ranger         # file manager
      yazi           # modern file manager
      bottom         # btm: system monitor TUI
      bandwhich      # network utilization TUI

      # Productivity
      obsidian       # note-taking
      xournalpp      # handwriting, note-taking & PDF annotation

      # Screenshots / recording
      flameshot
      obs-studio
      ffmpeg

      # Communication & Sync
      vesktop        # Discord (Vencord)
      element-desktop # Matrix client
      nextcloud-client

      # Password manager
      bitwarden-cli  # `bw` CLI

      # Office
      libreoffice

      # File sync
      syncthing
      rclone

      # Image / design
      gimp
      inkscape

      # Misc
      mpv
      vlc
      calibre        # ebook manager
    ];

    # ── Pointer cursor (default Adwaita) ──────────────────────────────
    pointerCursor = {
      enable     = true;
      gtk.enable = true;
      x11.enable = true;
      package    = pkgs.adwaita-icon-theme;
      name       = "Adwaita";
      size       = 24;
    };
  };

  # ── XDG ───────────────────────────────────────────────────────────────
  xdg = {
    enable = true;
    userDirs = {
      enable              = true;
      createDirectories   = true;
      setSessionVariables = false;   # new default in HM 26.05+
    };

    # Link Caffeine icons so St.IconTheme and GNOME Shell load the proper coffee cup
    dataFile."icons/hicolor/scalable/actions/my-caffeine-off-symbolic.svg".source =
      "${pkgs.gnomeExtensions.caffeine}/share/gnome-shell/extensions/caffeine@patapon.info/icons/hicolor/scalable/actions/my-caffeine-off-symbolic.svg";
    dataFile."icons/hicolor/scalable/actions/my-caffeine-on-symbolic.svg".source =
      "${pkgs.gnomeExtensions.caffeine}/share/gnome-shell/extensions/caffeine@patapon.info/icons/hicolor/scalable/actions/my-caffeine-on-symbolic.svg";
  };

  # ── Git ───────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    # HM 26.05+: userName/userEmail/extraConfig merged into settings
    settings = {
      user.name  = "kaltinsoy";
      user.email = "koray@anilkoray.tr";   # ← change if needed
      init.defaultBranch = "main";
      pull.rebase        = true;
      push.autoSetupRemote = true;
      core.pager         = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate     = true;
        light        = false;
        side-by-side = true;
        line-numbers = true;
      };
      merge.conflictstyle = "diff3";
      diff.colorMoved     = "default";
    };
    signing = {
      key       = null;
      signByDefault = false;
    };
  };

  # ── SSH ───────────────────────────────────────────────────────────────
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # HM 26.05+: addKeysToAgent moved into settings, matchBlocks → settings blocks
    settings = {
      "*" = {
        AddKeysToAgent = "yes";
      };
      "homelab" = {
        Hostname     = "192.168.122.100";
        User         = "root";
        IdentityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  # ── Syncthing ─────────────────────────────────────────────────────────
  services.syncthing.enable = true;

  # ── Nextcloud Client ──────────────────────────────────────────────────
  services.nextcloud-client = {
    enable            = true;
    startInBackground = true;
  };

  programs.home-manager.enable = true;
}
