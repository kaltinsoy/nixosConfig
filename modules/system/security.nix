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

  # ── PAM — GNOME keyring ───────────────────────────────────────────────
  security.pam.services = {
    gdm.enableGnomeKeyring = true;
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
