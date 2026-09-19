{ pkgs, ... }:

{
  # ── sudo ──────────────────────────────────────────────────────────────
  security.sudo = {
    enable         = true;
    wheelNeedsPassword = true;
    execWheelOnly  = true;
  };

  # ── polkit ────────────────────────────────────────────────────────────
  security.polkit.enable = true;

  # ── PAM — fingerprint + GNOME keyring ────────────────────────────────
  security.pam.services = {
    # GDM login: fingerprint OR password
    gdm.enableGnomeKeyring  = true;
    gdm-fingerprint = {
      text = ''
        auth    sufficient  pam_fprintd.so
        auth    include     gdm
        account include     gdm
        password include    gdm
        session include     gdm
      '';
    };

    # sudo: fingerprint OR password (fingerprint checked first)
    sudo = {
      fprintAuth = true;
    };

    # screen lock (GNOME screensaver / gdm-password)
    gdm-password.fprintAuth = true;

    # polkit / pkexec
    polkit-1.fprintAuth = true;
  };


  # ── rtkit for realtime audio (pipewire) ───────────────────────────────
  security.rtkit.enable = true;

  # ── AppArmor (optional hardening layer) ───────────────────────────────
  # security.apparmor.enable = true;

  # ── Kernel hardening ──────────────────────────────────────────────────
  boot.kernel.sysctl = {
    "kernel.dmesg_restrict"         = 1;
    "kernel.kptr_restrict"          = 2;
    "net.core.bpf_jit_harden"       = 2;
    "net.ipv4.conf.all.rp_filter"   = 2;  # 2 (loose) required for WireGuard & VPNs
    "net.ipv4.tcp_syncookies"        = 1;
    "kernel.unprivileged_userns_clone" = 1;  # needed by Nix sandbox & containers
  };

  # ── GPG agent ─────────────────────────────────────────────────────────
  programs.gnupg.agent = {
    enable           = true;
    enableSSHSupport = true;
    pinentryPackage  = pkgs.pinentry-gnome3;
  };
}
