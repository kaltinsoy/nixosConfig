{ inputs, username, spicetify-nix, zen-browser, nvchad-starter, antigravity-nix, pkgs, lib, config, ... }:

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
      # Dev tools & IDEs
      antigravity-nix.packages.${pkgs.system}.default
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
      qownnotes      # markdown note taking with Nextcloud integration

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
    # Route any *.anilkoray.tr host through Cloudflare Access
    Host *.anilkoray.tr
      ProxyCommand cloudflared access ssh --hostname %h

    # Match any Cloudflare Access host pattern (e.g., ssh.yourdomain.com)
    # Host cf-*
    #   ProxyCommand cloudflared access ssh --hostname %h

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

  # ── Bash shell configuration ──────────────────────────────────────────
  programs.bash = {
    enable = true;
    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake /home/koray/nixos-config#sumatra";
      nrb = "sudo nixos-rebuild boot --flake /home/koray/nixos-config#sumatra";
      nrt = "sudo nixos-rebuild test --flake /home/koray/nixos-config#sumatra";
      nfu = "nix flake update --flake /home/koray/nixos-config";
    };
    initExtra = ''
      # Automatically update window size on terminal resize (prevents typing wrap glitches)
      shopt -s checkwinsize
      # Ensure terminal auto-wrap mode is active
      [ -t 1 ] && tput smam 2>/dev/null || true
    '';
  };

  programs.home-manager.enable = true;
}
