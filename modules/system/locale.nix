{ ... }:

{
  time.timeZone = "Europe/Istanbul";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME      = "tr_TR.UTF-8";
      LC_MONETARY  = "tr_TR.UTF-8";
    };
  };

  console = {
    font      = "Lat2-Terminus16";
    keyMap    = "trq";   # Turkish Q layout; change to "us" if preferred
  };

  services.xserver.xkb = {
    layout  = "tr";
    variant = "";
  };
}
