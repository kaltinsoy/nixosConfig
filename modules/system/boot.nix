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

  # kvm-intel comes from hardware-configuration.nix; acpi_call is loaded in lenovo.nix.
  boot.extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];

  # ── tmpfs on /tmp ─────────────────────────────────────────────────────
  boot.tmp = {
    useTmpfs  = true;
    tmpfsSize = "8G";
  };

  # ── Plymouth boot splash ──────────────────────────────────────────────
  boot.plymouth.enable = true;
}
