{ pkgs, ... }:

{
  # ── Audio — PipeWire ──────────────────────────────────────────────────
  services.pulseaudio.enable = false;   # replaced by PipeWire

  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
    jack.enable       = true;
    wireplumber.enable = true;
  };

  # ── Bluetooth ─────────────────────────────────────────────────────────
  hardware.bluetooth = {
    enable      = true;
    powerOnBoot = true;
    settings.General.Experimental = true;
  };
  services.blueman.enable = true;

  # ── Printing ──────────────────────────────────────────────────────────
  services.printing = {
    enable   = true;
    drivers  = with pkgs; [ gutenprint cups-bjnp ];
  };
  services.avahi.publish = {
    enable        = true;
    userServices  = true;
  };

  # ── D-Bus ─────────────────────────────────────────────────────────────
  services.dbus.enable = true;

  # ── Udev ─────────────────────────────────────────────────────────────
  services.udev.packages = with pkgs; [
    openocd                # JTAG / SWD probes
  ];

  # ── Firmware update (fwupd) — see lenovo.nix for more ────────────────
  services.fwupd.enable = true;

  # ── Flatpak (optional; useful for Burp Suite Pro, etc.) ───────────────
  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gnome ];
  };

  # ── Keybase (optional) ────────────────────────────────────────────────
  # services.keybase.enable = true;

  # ── Thermald (Intel thermal daemon) ──────────────────────────────────
  services.thermald.enable = true;
}
