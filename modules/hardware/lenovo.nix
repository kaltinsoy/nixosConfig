{ pkgs, lib, config, ... }:

{
  # ══════════════════════════════════════════════════════════════════════
  #  ThinkPad T480s — Hardware Management
  #  • Intel 8th-gen (Kaby Lake R / Whiskey Lake)
  #  • Single internal battery (BAT0)
  #  • Synaptics fingerprint reader (06cb:00bd)
  #  • Sierra Wireless EM7455 / Fibocom L850-GL WWAN (LTE SIM slot)
  #  • TrackPoint + ClickPad
  # ══════════════════════════════════════════════════════════════════════

  # ── TLP — power management ────────────────────────────────────────────
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC  = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC  = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_BOOST_ON_AC  = 1;
      CPU_BOOST_ON_BAT = 0;
      CPU_HWP_DYN_BOOST_ON_AC  = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;

      # T480s — single battery (BAT0 only)
      START_CHARGE_THRESH_BAT0 = 20;
      STOP_CHARGE_THRESH_BAT0  = 80;
      NATACPI_ENABLE = 1;
      TPACPI_ENABLE  = 1;
      TPSMAPI_ENABLE = 0;   # T480s uses ACPI, not SMAPI

      # USB — keep WWAN modem from being autosuspended
      USB_AUTOSUSPEND = 1;
      USB_DENYLIST    = "1199:9079 1199:9041 2cb7:0104";

      PCIE_ASPM_ON_BAT      = "powersupersave";
      DISK_DEVICES          = "nvme0n1";
      DISK_APM_LEVEL_ON_BAT = "128";
      WIFI_PWR_ON_AC        = "off";
      WIFI_PWR_ON_BAT       = "on";
      RUNTIME_PM_ON_AC      = "on";
      RUNTIME_PM_ON_BAT     = "auto";
      WWAN_POWERSAVE_ENABLE_ON_BAT = 0;
    };
  };

  # ── throttled — Intel 8th-gen undervolting ────────────────────────────
  services.throttled = {
    enable = true;
    extraConfig = ''
      [GENERAL]
      Enabled=True
      Sysfs_Power_Path=/sys/class/power_supply/AC*/online
      Autoreload=False

      [BATTERY]
      Update_Rate_s=30
      PL1_Tdp_W=20
      PL1_Duration_s=28
      PL2_Tdp_W=30
      PL2_Duration_s=0.002
      Trip_Temp_C=85
      cTDP=0
      Disable_BDPROCHOT=False

      [AC]
      Update_Rate_s=5
      PL1_Tdp_W=40
      PL1_Duration_s=28
      PL2_Tdp_W=50
      PL2_Duration_s=0.002
      Trip_Temp_C=95
      cTDP=2
      Disable_BDPROCHOT=False

      [UNDERVOLT.BATTERY]
      CORE     = -80
      GPU      = -60
      CACHE    = -80
      UNCORE   = -60
      ANALOGIO = 0

      [UNDERVOLT.AC]
      CORE     = -100
      GPU      = -80
      CACHE    = -100
      UNCORE   = -80
      ANALOGIO = 0
    '';
  };

  # ── thinkfan ──────────────────────────────────────────────────────────
  services.thinkfan = {
    enable  = true;
    levels  = [
      [0  0  55]
      [1  53 60]
      [2  58 65]
      [3  63 72]
      [6  70 80]
      [7  78 85]
      ["level full-speed" 82 32767]
    ];
    sensors = [
      { type = "tpacpi"; query = "/proc/acpi/ibm/thermal"; indices = [0]; }
    ];
  };

  # power-profiles-daemon conflicts with TLP
  services.power-profiles-daemon.enable = lib.mkForce false;

  # ── Fingerprint reader (Synaptics 06cb:009a) ──────────────────────────
  # Note: 06cb:009a is a proprietary match-on-host sensor not supported
  # by standard libfprint/fprintd (requires python-validity / open-fprintd).
  # Disabled to prevent "No such device" errors and PAM auth delays.
  services.fprintd.enable = false;

  # ── WWAN / LTE SIM ────────────────────────────────────────────────────
  # Correct NixOS option: networking.modemmanager (not services.modemManager)
  networking.modemmanager = {
    enable = true;
    fccUnlockScripts = [
      {  # Sierra Wireless EM7455
        id   = "1199:9079";
        path = "${pkgs.modemmanager}/share/ModemManager/fcc-unlock.available.d/1199:9079";
      }
      {  # Fibocom L850-GL
        id   = "2cb7:0104";
        path = "${pkgs.modemmanager}/share/ModemManager/fcc-unlock.available.d/2cb7:0104";
      }
    ];
  };

  # NetworkManager VPN plugins (packages, not a NM option)
  environment.systemPackages = with pkgs; [
    powertop
    acpi
    acpitool
    s-tui
    lm_sensors
    i7z
    cpu-x

    # WWAN / SIM
    modemmanager
    libmbim
    libqmi
    networkmanagerapplet
    networkmanager-openconnect
    networkmanager-openvpn

    # Power / Backlight
    brightnessctl   # backlight control (replaces light)
  ];

  # ── Thermald + fwupd ──────────────────────────────────────────────────
  services.thermald.enable = true;
  services.fwupd.enable    = true;

  # ── zram swap ─────────────────────────────────────────────────────────
  zramSwap = {
    enable        = true;
    algorithm     = "zstd";
    memoryPercent = 50;
  };

  # ── Kernel modules ────────────────────────────────────────────────────
  boot.kernelModules = [
    "acpi_call"     # battery/fan ACPI control
    "thinkpad_acpi" # ThinkPad extras (fan, hotkeys, LED)
    # kvm-intel already set in boot.nix
  ];
  # acpi_call is already added to boot.extraModulePackages in boot.nix

  # ── TrackPoint tuning ─────────────────────────────────────────────────
  systemd.tmpfiles.rules = [
    "w /sys/devices/platform/i8042/serio1/serio2/sensitivity - - - - 200"
    "w /sys/devices/platform/i8042/serio1/serio2/speed       - - - - 97"
    "w /sys/devices/platform/i8042/serio1/serio2/inertia     - - - - 6"
  ];

  # ── Backlight + udev ──────────────────────────────────────────────────
  # programs.light was removed from nixpkgs; use brightnessctl instead
  # brightnessctl respects the video group without udev rules

  services.udev.extraRules = ''
    # Backlight — writable by video group
    ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", \
      RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", \
      RUN+="${pkgs.coreutils}/bin/chmod g+w   /sys/class/backlight/%k/brightness"

    # Fingerprint reader — Synaptics 06cb:00bd
    ATTRS{idVendor}=="06cb", ATTRS{idProduct}=="00bd", \
      MODE="0660", GROUP="input", TAG+="uaccess"

    # Sierra Wireless EM7455 WWAN
    ATTRS{idVendor}=="1199", ATTRS{idProduct}=="9079", \
      ENV{ID_MM_DEVICE_IGNORE}="0"
    # Fibocom L850-GL WWAN
    ATTRS{idVendor}=="2cb7", ATTRS{idProduct}=="0104", \
      ENV{ID_MM_DEVICE_IGNORE}="0"
  '';

  # ── Ambient light sensor ──────────────────────────────────────────────
  # hardware.sensor.iio is provided by nixos-hardware lenovo-thinkpad-t480s preset
  # No need to set it here; the preset enables it automatically.
}
