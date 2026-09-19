{ pkgs, ... }:

{
  # ── libvirtd ──────────────────────────────────────────────────────────
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      # OVMF (UEFI) is now bundled with QEMU by default; no config needed
      runAsRoot    = true;
      swtpm.enable = true;   # TPM emulation for Win11 VMs
    };
    onBoot     = "ignore";
    onShutdown = "shutdown";
  };

  # ── Docker ────────────────────────────────────────────────────────────
  virtualisation.docker = {
    enable           = true;
    autoPrune.enable = true;
    daemon.settings  = {
      dns            = [ "1.1.1.1" "8.8.8.8" ];
      storage-driver = "overlay2";
    };
  };

  # ── Networking for VMs ────────────────────────────────────────────────
  # NOTE: nftables + iptables conflict; libvirt uses iptables by default,
  #       so keep nftables disabled unless you configure libvirt for nftables.
  networking.bridges.virbr0.interfaces = [];  # libvirt manages virbr0

  # ── Packages ──────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # QEMU / KVM management
    virt-manager
    virt-viewer
    virtio-win          # VirtIO drivers ISO for Windows guests
    virtiofsd           # Virtiofs host daemon
    spice-vdagent       # SPICE clipboard/display
    swtpm               # Software TPM

    # Container tooling
    docker-compose
    dive                # inspect Docker layers
    ctop                # container top
    lazydocker

    # Network / bridging
    bridge-utils
    dnsmasq
    iptables
    iproute2

    # Optional GPU passthrough
    looking-glass-client  # low-latency VM display (requires IVSHMEM setup)
  ];

  # ── SPICE & USB redirect ──────────────────────────────────────────────
  services.spice-vdagentd.enable = true;

  # ── virt-manager ──────────────────────────────────────────────────────
  programs.virt-manager.enable = true;
}
