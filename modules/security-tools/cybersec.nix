{ pkgs, ... }:

{
  # ══════════════════════════════════════════════════════════════════════
  #  Cybersecurity Lab Configuration
  #  All penetration testing, reverse engineering, and security tools
  #  are hosted inside ParrotOS (via QEMU/KVM virtual machines or Distrobox).
  #  This keeps the NixOS host clean, lean, and fast.
  # ══════════════════════════════════════════════════════════════════════

  # ── Host-level networking for ParrotOS VM / Container labs ──────────
  boot.kernel.sysctl = {
    # Allow raw socket operations
    "net.ipv4.ping_group_range"   = "0 65535";
    # Enable IP forwarding for routing / MITM / VM lab traffic
    "net.ipv4.ip_forward"         = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
}
