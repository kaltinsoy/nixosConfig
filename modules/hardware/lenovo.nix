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
      # Equivalent to Lenovo Vantage "Battery Conservation Mode":
      # Stops charging at 80% on AC to prevent battery degradation;
      # Re-starts charging when plugged in below 75%.
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0  = 80;
      NATACPI_ENABLE = 1;
      TPACPI_ENABLE  = 1;
      TPSMAPI_ENABLE = 0;   # T480s uses ACPI, not SMAPI

      # USB — keep WWAN modem and fingerprint reader from being autosuspended
      USB_AUTOSUSPEND = 1;
      USB_DENYLIST    = "1199:9079 1199:9041 2cb7:0104 06cb:009a";

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

  # power-profiles-daemon conflicts with TLP; use tlp-pd as the D-Bus bridge
  # so GNOME displays its Performance / Balanced / Power Saver slider in Quick Settings
  services.power-profiles-daemon.enable = lib.mkForce false;
  systemd.packages = [ pkgs.tlp-pd ];
  services.dbus.packages = [ pkgs.tlp-pd ];
  systemd.services.tlp-pd.wantedBy = [ "graphical.target" ];

  # ── Fingerprint reader (Synaptics 06cb:009a) ──────────────────────────
  # Proprietary Match-on-Host sensor driven by ahbnr/nixos-06cb-009a-fingerprint-sensor flake.
  # Stage 2: Native libfprint-tod PAM integration with calibration data
  services."06cb-009a-fingerprint-sensor" = {
    enable          = true;
    backend         = "libfprint-tod";
    calib-data-file = ./calib-data.bin;
  };

  # ── Facial Recognition (Howdy) ────────────────────────────────────────
  # Uses the 720p HD Integrated Camera (Port 8 / 5986:2115).
  # The 160x120 IR sensor (Port 5) cannot stream frames under Linux UVC.
  services.howdy = {
    enable  = true;
    control = "sufficient";
    settings = {
      video = {
        # ThinkPad T480s 720p HD Integrated Camera (Port 8)
        device_path    = "/dev/v4l/by-path/pci-0000:00:14.0-usb-0:8:1.0-video-index0";
        dark_threshold = 60;
        certainty      = 3.5;
      };
      core = {
        no_confirmation     = true; # Authenticate immediately upon face match
        abort_if_lid_closed = true;
        abort_if_ssh        = true;
      };
    };
  };

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

    # Power / Backlight / Audio
    brightnessctl   # backlight control (replaces light)
    tlp-pd          # tlpctl CLI and D-Bus bridge
    pulseaudio      # pactl CLI for audio routing and LED sync

    # Logitech Gaming Mouse GUI (libratbag / ratbagd frontend)
    piper
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

  # ── Howdy symlink ─────────────────────────────────────────────────────
  systemd.tmpfiles.rules = [
    # Ensure /etc/howdy points to /etc/static/howdy for Howdy CLI and PAM
    "L+ /etc/howdy - - - - /etc/static/howdy"
    # Ensure /etc/tlp.conf is available for TLP CLI commands
    "L+ /etc/tlp.conf - - - - /etc/static/tlp.conf"
  ];

  # ── Backlight, Fingerprint, TrackPoint + udev ─────────────────────────
  # programs.light was removed from nixpkgs; use brightnessctl instead
  # brightnessctl respects the video group without udev rules

  services.udev.extraRules = ''
    # Backlight — writable by video group
    ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", \
      RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", \
      RUN+="${pkgs.coreutils}/bin/chmod g+w   /sys/class/backlight/%k/brightness"

    # ThinkPad battery charge threshold access without root (for tlp-profile / ac-bypass)
    ACTION=="add|change", SUBSYSTEM=="power_supply", KERNEL=="BAT[0-9]*", \
      RUN+="${pkgs.coreutils}/bin/chmod 0666 /sys/class/power_supply/%k/charge_control_start_threshold /sys/class/power_supply/%k/charge_control_end_threshold /sys/class/power_supply/%k/charge_start_threshold /sys/class/power_supply/%k/charge_stop_threshold"

    # Fingerprint reader — Synaptics 06cb:009a (disable USB autosuspend)
    ATTRS{idVendor}=="06cb", ATTRS{idProduct}=="009a", \
      MODE="0660", GROUP="input", TAG+="uaccess", \
      TEST=="power/control", ATTR{power/control}="on"

    # TrackPoint tuning — matched by driver, not by serio path (survives renumbering & boot races)
    ACTION=="add|change", SUBSYSTEM=="serio", DRIVERS=="psmouse", \
      ATTR{sensitivity}="200", ATTR{speed}="97", ATTR{inertia}="6"

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

  # ── WirePlumber Camera Priority & Exclusion ───────────────────────────
  # Disable the 160x120 IR camera (Port 5) in WirePlumber so desktop apps
  # (GNOME Snapshot / Camera, browsers, etc.) only see and use the 720p HD
  # Integrated Camera (Port 8), preventing IR blinking and low-res feeds.
  services.pipewire.wireplumber.extraConfig = {
    "10-camera-priority" = {
      "monitor.v4l2.rules" = [
        {
          matches = [
            { "node.name" = "~v4l2_input.*0_5_1.0*"; }
          ];
          actions = {
            update-props = {
              "node.disabled" = true;
              "priority.session" = 500;
            };
          };
        }
        {
          matches = [
            { "node.name" = "~v4l2_input.*0_8_1.0*"; }
          ];
          actions = {
            update-props = {
              "node.disabled" = false;
              "priority.session" = 1500;
            };
          };
        }
      ];
      "monitor.libcamera.rules" = [
        {
          matches = [
            { "device.name" = "~libcamera_device.*HS05*"; }
          ];
          actions = {
            update-props = {
              "device.disabled" = true;
            };
          };
        }
      ];
    };
  };

  # ── Logitech Wireless Devices & Mouse Configuration ──────────────────
  hardware.logitech.wireless.enable = true;
  programs.solaar.enable            = true; # Solaar GUI for pairing, battery indicator & status

  # ratbagd daemon for Logitech gaming mice (DPI, buttons, onboard profiles)
  services.ratbagd.enable = true;

  # ── ThinkPad Audio Mute & Mic Mute LED Synchronization ────────────────
  # ThinkPad F1 (speaker mute) and F4 (mic mute) LEDs are hardware-driven
  # by ALSA's kernel driver watching the internal Realtek ALC257 sound card.
  # When using Bluetooth (e.g. earbuds) or USB audio, WirePlumber toggles the
  # default endpoint while leaving the internal sound card out of sync, causing
  # the F4 mic mute LED to get stuck ON and the F1 mute LED to stay OFF.
  # This lightweight systemd user service watches PipeWire/PulseAudio events
  # and mirrors mute state between default endpoints, the internal card, and LEDs.
  systemd.user.services.thinkpad-mute-led = {
    description = "ThinkPad Audio Mute and Mic Mute LED Synchronization";
    wantedBy = [ "default.target" ];
    after = [ "pipewire.service" "pipewire-pulse.service" "wireplumber.service" ];
    partOf = [ "pipewire.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.writeScript "thinkpad-mute-led" ''
        #!${pkgs.python3}/bin/python3
        import subprocess, time, os, sys

        PACTL = "${pkgs.pulseaudio}/bin/pactl"
        BRIGHTNESSCTL = "${pkgs.brightnessctl}/bin/brightnessctl"
        STDBUF = "${pkgs.coreutils}/bin/stdbuf"

        def find_internal(kind):
            try:
                out = subprocess.run([PACTL, "list", "short", f"{kind}s"], capture_output=True, text=True).stdout
                prefix = "alsa_output." if kind == "sink" else "alsa_input."
                candidates = []
                for line in out.splitlines():
                    parts = line.split()
                    if len(parts) >= 2:
                        name = parts[1]
                        if name.startswith(prefix) and not name.endswith(".monitor"):
                            candidates.append(name)
                for c in candidates:
                    if "analog-stereo" in c:
                        return c
                return candidates[0] if candidates else None
            except Exception:
                return None

        def get_mute(kind, target):
            try:
                res = subprocess.run([PACTL, f"get-{kind}-mute", target], capture_output=True, text=True).stdout
                return "yes" in res.lower()
            except Exception:
                return False

        def set_mute(kind, target, mute):
            try:
                subprocess.run([PACTL, f"set-{kind}-mute", target, "1" if mute else "0"], capture_output=True)
            except Exception:
                pass

        def set_led(dev_name, val):
            if os.path.exists(f"/sys/class/leds/{dev_name}"):
                try:
                    subprocess.run([BRIGHTNESSCTL, f"--device={dev_name}", "set", str(val)], capture_output=True)
                except Exception:
                    pass

        def sync_all():
            # Sink (speaker mute - F1)
            int_sink = find_internal("sink")
            sink_mute = get_mute("sink", "@DEFAULT_SINK@")
            set_led("platform::mute", 1 if sink_mute else 0)
            if int_sink:
                cur_sink = get_mute("sink", int_sink)
                if cur_sink != sink_mute:
                    set_mute("sink", int_sink, sink_mute)

            # Source (mic mute - F4)
            int_src = find_internal("source")
            src_mute = get_mute("source", "@DEFAULT_SOURCE@")
            set_led("platform::micmute", 1 if src_mute else 0)
            if int_src:
                cur_src = get_mute("source", int_src)
                if cur_src != src_mute:
                    set_mute("source", int_src, src_mute)

        def main():
            while True:
                proc = None
                try:
                    sync_all()
                    proc = subprocess.Popen(
                        [STDBUF, "-oL", PACTL, "subscribe"],
                        stdout=subprocess.PIPE,
                        text=True,
                        bufsize=1,
                    )
                    while True:
                        line = proc.stdout.readline()
                        if not line:
                            break
                        if any(f"on {k}" in line for k in ["sink", "source", "server"]):
                            sync_all()
                except Exception:
                    pass
                finally:
                    if proc:
                        try:
                            proc.terminate()
                            proc.wait(timeout=1)
                        except Exception:
                            pass
                time.sleep(2)

        if __name__ == "__main__":
            main()
      ''}";
      Restart = "on-failure";
      RestartSec = "3s";
    };
  };
}
