{ pkgs, config, lib, ... }:

{
  # ── Bootloader ────────────────────────────────────────────────────────
  boot.loader = {
    systemd-boot = {
      enable             = true;
      configurationLimit = 10;
    };
    efi.canTouchEfiVariables = true;
  };

  # ── Kernel ────────────────────────────────────────────────────────────
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelParams = [
    # Intel IOMMU for QEMU passthrough
    "intel_iommu=on"
    "iommu=pt"
    # Power tweaks
    "mem_sleep_default=deep"
    "nvme.noacpi=1"
  ];

  # Extra kernel modules — kvm-intel and acpi_call are also set in lenovo.nix;
  # they merge safely via mkMerge, no conflict.
  boot.kernelModules      = [ "kvm-intel" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];

  # ── tmpfs on /tmp ─────────────────────────────────────────────────────
  boot.tmp = {
    useTmpfs  = true;
    tmpfsSize = "8G";
  };

  # ── Plymouth boot splash ──────────────────────────────────────────────
  boot.plymouth.enable = true;
}
