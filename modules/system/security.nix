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

  # Bitwarden Desktop biometrics integration:
  # 1. System package ensures NixOS links the polkit policy into the system environment
  # 2. tmpfiles rules link the policy to /usr/share and /etc where Bitwarden checks for it
  environment.systemPackages = [ pkgs.bitwarden-desktop ];

  systemd.tmpfiles.rules = [
    "L+ /usr/share/polkit-1/actions/com.bitwarden.Bitwarden.policy - - - - ${pkgs.bitwarden-desktop}/share/polkit-1/actions/com.bitwarden.Bitwarden.policy"
    "L+ /etc/polkit-1/actions/com.bitwarden.Bitwarden.policy - - - - ${pkgs.bitwarden-desktop}/share/polkit-1/actions/com.bitwarden.Bitwarden.policy"
  ];

  # ── PAM — Biometrics & Keyring ────────────────────────────────────────
  security.pam.services = {
    gdm.enableGnomeKeyring = true;

    # Bitwarden uses Polkit for biometric unlock on Linux
    polkit-1 = {
      howdy.enable  = true;
      howdy.control = "sufficient";
      fprintAuth    = true;
      rules.auth.fprintd = {
        order = 11400;
        args = [ "max-tries=1" "timeout=10" ];
      };
    };

    # Sudo authentication with biometrics
    sudo = {
      howdy.enable  = true;
      howdy.control = "sufficient";
      fprintAuth    = true;
      rules.auth.fprintd = {
        order = 11400;
        args = [ "max-tries=1" "timeout=10" ];
      };
    };

    # GDM password / login / lockscreen with biometrics
    gdm-password = {
      howdy.enable  = true;
      howdy.control = "sufficient";
    };
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
