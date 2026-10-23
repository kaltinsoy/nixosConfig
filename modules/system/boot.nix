{ pkgs, config, lib, ... }:

{
  # ── Bootloader ────────────────────────────────────────────────────────
  boot.loader = {
    systemd-boot = {
      enable             = true;
      configurationLimit = 3;
    };
    efi.canTouchEfiVariables = true;
  };

  # ── Kernel ────────────────────────────────────────────────────────────
  boot.kernelPackages = pkgs.linuxPackages;  # LTS kernel (Linux 6.x)

  boot.kernelParams = [
    # Intel IOMMU for QEMU passthrough
    "intel_iommu=on"
    "iommu=pt"
    # Power tweaks
    "mem_sleep_default=deep"
    "nvme.noacpi=1"
  ];

  # kvm-intel comes from hardware-configuration.nix.
  # No acpi_call: the T480s's thinkpad_acpi already exposes charge thresholds and
  # charge_behaviour (force-discharge / inhibit-charge) natively, and the out-of-tree
  # module broke the kernel-modules build (nixpkgs now wants a per-module .ko.cer).

  # ── tmpfs on /tmp ─────────────────────────────────────────────────────
  boot.tmp = {
    useTmpfs  = true;
    tmpfsSize = "8G";
  };

  # ── Plymouth boot splash ──────────────────────────────────────────────
  boot.plymouth.enable = true;

  # ── Supported Filesystems ─────────────────────────────────────────────
  boot.supportedFilesystems = [ "nfs" ];
}
