{ inputs, username, spicetify-nix, zen-browser, nvchad-starter, antigravity-nix, pkgs, lib, config, ... }:

{
  imports = [
    ./neovim/neovim.nix
    ./apps/browsers.nix
    ./apps/media.nix
    ./gnome-extensions/extensions.nix
  ];

  home = {
    username    = username;
    homeDirectory = "/home/${username}";
    stateVersion = "25.05";

    # ── Common home packages ──────────────────────────────────────────
    packages = with pkgs; [
      # Dev tools & IDEs
      antigravity-nix.packages.${pkgs.system}.default
      claude-code    # Anthropic's agentic coding CLI (claude)
      gh             # GitHub CLI
      git-credential-oauth
      lazygit
      delta          # better git diff
      difftastic
      pre-commit
      cloudflared    # Cloudflare Tunnel & SSH Access proxy

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
      anki           # flashcards & spaced repetition

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
      onlyoffice-desktopeditors # OnlyOffice desktop editors
      qownnotes      # markdown note taking with Nextcloud integration

      # Image / design
      gimp
      inkscape

      # Audio / Video & Misc
      easyeffects    # DSP audio effects (manual launch)
      mpv
      vlc
      calibre        # ebook manager
    ];

    # ── Pointer cursor (consistent across GTK, X11, Wayland) ──────────
    # Under GNOME Wayland with 125% fractional scaling:
    # - Native Wayland apps (Anki/Qt6, GTK4, Zen, etc.) use base size 24
    #   (which Mutter scales by 1.25x to 30px on screen).
    # - X11/XWayland apps (OnlyOffice, Steam, GIMP, etc.) use xrdb where
    #   Mutter sets Xcursor.size = 48 (which Mutter scales down by 1.6x
    #   to 30px on screen).
    # - Setting XCURSOR_SIZE in the environment overrides xrdb and breaks
    #   either XWayland apps (if set to 24 -> 15px tiny pointer) or
    #   Wayland Qt apps like Anki (if set to 48 -> 60px giant pointer).
    # - By setting x11.size = 48 (for .Xresources) and explicitly unsetting
    #   XCURSOR_SIZE (XCURSOR_SIZE = null), XWayland apps read 48 from xrdb,
    #   and Wayland apps read 24 from GSettings/compositor. Both result in
    #   an identical 30px cursor on screen across all installed and future apps!
    pointerCursor = {
      enable     = true;
      gtk.enable = true;
      x11 = {
        enable = true;
        size   = 48;
      };
      package    = pkgs.adwaita-icon-theme;
      name       = "Adwaita";
      size       = 24;
    };

    # ── Session Variables ──────────────────────────────────────────────
    sessionVariables = {
      XCURSOR_SIZE = pkgs.lib.mkForce null; # Do NOT export XCURSOR_SIZE to environment
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

    # Default application associations
    mimeApps = {
      enable = true;
      defaultApplications = {
        # Web & HTML -> Zen Browser (primary) with Firefox fallback
        "text/html"                                                               = [ "zen-beta.desktop" "firefox.desktop" ];
        "application/xhtml+xml"                                                   = [ "zen-beta.desktop" "firefox.desktop" ];
        "x-scheme-handler/http"                                                   = [ "zen-beta.desktop" "firefox.desktop" ];
        "x-scheme-handler/https"                                                  = [ "zen-beta.desktop" "firefox.desktop" ];
        "x-scheme-handler/about"                                                  = [ "zen-beta.desktop" "firefox.desktop" ];
        "x-scheme-handler/unknown"                                                = [ "zen-beta.desktop" "firefox.desktop" ];

        # Plain Text, Markdown & Markup -> Text Editor / Obsidian
        "text/plain"                                                              = [ "org.gnome.TextEditor.desktop" ];
        "text/x-markdown"                                                         = [ "obsidian.desktop" "org.gnome.TextEditor.desktop" ];
        "text/markdown"                                                           = [ "obsidian.desktop" "org.gnome.TextEditor.desktop" ];
        "application/xml"                                                         = [ "org.gnome.TextEditor.desktop" ];
        "text/xml"                                                                = [ "org.gnome.TextEditor.desktop" ];

        # PDF Documents -> GNOME Papers / Evince
        "application/pdf"                                                         = [ "org.gnome.Papers.desktop" "org.gnome.Evince.desktop" ];

        # Rich Text & Word documents -> OnlyOffice
        "text/rtf"                                                                = [ "onlyoffice-desktopeditors.desktop" ];
        "application/rtf"                                                         = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.ms-word.document.macroenabled.12"                        = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/msword"                                                      = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.oasis.opendocument.text"                                 = [ "onlyoffice-desktopeditors.desktop" ];

        # Spreadsheets -> OnlyOffice
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"       = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.ms-excel"                                                = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.oasis.opendocument.spreadsheet"                          = [ "onlyoffice-desktopeditors.desktop" ];

        # Presentations -> OnlyOffice
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.ms-powerpoint"                                           = [ "onlyoffice-desktopeditors.desktop" ];
        "application/vnd.oasis.opendocument.presentation"                         = [ "onlyoffice-desktopeditors.desktop" ];

        # E-books (only genuine ebook formats) -> Calibre E-book viewer
        "application/epub+zip"                                                    = [ "calibre-ebook-viewer.desktop" ];
        "application/x-mobipocket-ebook"                                          = [ "calibre-ebook-viewer.desktop" ];
        "application/x-mobi8-ebook"                                               = [ "calibre-ebook-viewer.desktop" ];
        "text/fb2+xml"                                                            = [ "calibre-ebook-viewer.desktop" ];
      };
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
  # OpenSSH requires ~/.ssh/config to be owned by the user with 0600 permissions.
  # A direct symlink into /nix/store triggers "Bad owner or permissions" because
  # the store UID differs. An activation script writes a real file with 0600.
  home.activation.sshConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p $HOME/.ssh
    chmod 700 $HOME/.ssh
    rm -f $HOME/.ssh/config
    cat << 'EOF' > $HOME/.ssh/config
    Host homelab
      Hostname 192.168.122.100
      IdentityFile ~/.ssh/id_ed25519
      User root

    # Cloudflare Access SSH Proxy
    Host sshl.ras-pi.tr
      ProxyCommand cloudflared access ssh --hostname %h

    Host ssh.ras-pi.tr
      ProxyCommand cloudflared access ssh --hostname %h

    Host server.anilkoray.tr
      ProxyCommand cloudflared access ssh --hostname %h

    # Route any *.anilkoray.tr or *.ras-pi.tr host through Cloudflare Access
    Host *.anilkoray.tr *.ras-pi.tr
      ProxyCommand cloudflared access ssh --hostname %h

    Host *
      AddKeysToAgent yes
    EOF
    chmod 600 $HOME/.ssh/config
  '';

  # ── Nextcloud Client ──────────────────────────────────────────────────
  services.nextcloud-client = {
    enable            = true;
    startInBackground = true;
  };

  # ── EasyEffects Audio Enhancement ─────────────────────────────────────
  # DSP audio effects (EQ, limiter, loudness) for ThinkPad laptop speakers.
  # Autostart service is disabled so it does not launch on boot/login.
  # Launch manually via 'easyeffects' when desired.
  services.easyeffects = {
    enable = false;
  };

  # ── Bash shell configuration ──────────────────────────────────────────
  programs.bash = {
    enable = true;
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake /home/koray/nixos-config#sumatra";
      nrb = "sudo nixos-rebuild boot --flake /home/koray/nixos-config#sumatra";
      nrt = "sudo nixos-rebuild test --flake /home/koray/nixos-config#sumatra";
      nfu = "nix flake update --flake /home/koray/nixos-config";
      nclean = "nclean";
      ncg = "nclean";
      logisim-evo = "logisim-evolution";
      logisim     = "logisim-evolution";
    };
    initExtra = ''
      # User bin directories in PATH
      export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
      # Automatically update window size on terminal resize (prevents typing wrap glitches)
      shopt -s checkwinsize
      # Ensure terminal auto-wrap mode is active
      [ -t 1 ] && tput smam 2>/dev/null || true
    '';
  };

  programs.home-manager.enable = true;
}
