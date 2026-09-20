{ pkgs, ... }:

{
  fonts = {
    enableDefaultPackages = true;

    packages = with pkgs; [
      # Nerd Fonts (icons + programming ligatures)
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.hack
      nerd-fonts.caskaydia-cove  # CaskaydiaCove = Cascadia Code Nerd Font

      # UI fonts
      inter
      roboto
      source-sans-pro
      source-serif-pro

      # Mono / coding
      jetbrains-mono
      fira-code
      cascadia-code

      # Emoji
      noto-fonts-color-emoji
      twemoji-color-font

      # CJK (optional but useful for VM guest OSes in QEMU)
      noto-fonts-cjk-sans

      # Arabic / Turkish extended
      noto-fonts
    ];

    fontconfig = {
      defaultFonts = {
        monospace  = [ "JetBrainsMono Nerd Font Mono" "JetBrains Mono" "FiraCode Nerd Font" ];
        sansSerif  = [ "Inter" "Noto Sans" ];
        serif      = [ "Source Serif Pro" "Noto Serif" ];
        emoji      = [ "Noto Color Emoji" ];
      };
      antialias     = true;
      hinting = {
        enable = true;
        style  = "slight";
      };
      subpixel.rgba = "none"; # Grayscale antialiasing for fractional scaling and high DPI screens
    };
  };
}
