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

      # Screenshots / recording
      flameshot
      obs-studio
      ffmpeg

      # Communication
      vesktop        # Discord (Vencord)
      element-desktop # Matrix client

      # Password manager
      bitwarden-desktop
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

      # Desktop themes & cursors
      bibata-cursors
      papirus-icon-theme
      adw-gtk3
    ];

    # ── Pointer cursor (consistent across GTK, X11, Wayland) ──────────
    pointerCursor = {
      enable     = true;
      gtk.enable = true;
      x11.enable = true;
      package    = pkgs.bibata-cursors;
      name       = "Bibata-Modern-Ice";
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

  programs.home-manager.enable = true;
}
