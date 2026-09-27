{ pkgs, lib, ... }:

let
  # ── FHS environment for proprietary EDA tools ─────────────────────────
  # Vivado and Gowin EDA ship bundled binaries that expect a "normal" Linux
  # filesystem layout. buildFHSEnv creates a chroot that satisfies that.

  vivadoPkgs = p: with p; [
    # C/C++ runtime & build tools
    glibc glibc.dev glib gcc-unwrapped.lib
    # Graphics & X11 (including all libraries required by installLibs.sh)
    libGL libGLU libx11 libxrender libxtst libxi
    libxext libxcb libxft libxcursor libxfixes
    libxcomposite libxscrnsaver motif
    gtk3 gdk-pixbuf
    # Audio
    alsa-lib
    # Crypto & Security
    openssl libsecret nss libxcrypt-legacy
    # Utilities, parsing, and graph visualization (used by Vivado schematics)
    graphviz libyaml nettools procps
    unzip zip
    # Terminal, fonts & legacy libs
    ncurses5 zlib freetype fontconfig
    coreutils bash which
    # Java (Vivado 2022+ bundles its own, but some versions need system Java)
    temurin-bin-17
  ];

  vivadoFHS = pkgs.buildFHSEnv {
    name = "vivado";
    targetPkgs = vivadoPkgs;
    runScript = pkgs.writeScript "vivado-run" ''
      #!/bin/bash
      # If the first argument is an executable file or script, run it directly
      if [ $# -gt 0 ] && [ -f "$1" ] && [ -x "$1" ]; then
        exec -- "$@"
      fi

      XILINX_ROOT="''${XILINX_ROOT:-/opt/Xilinx}"
      if [ -f "$XILINX_ROOT/Vivado/settings64.sh" ]; then
        SETTINGS="$XILINX_ROOT/Vivado/settings64.sh"
      elif [ -f "$XILINX_ROOT/2026.1/Vivado/settings64.sh" ]; then
        SETTINGS="$XILINX_ROOT/2026.1/Vivado/settings64.sh"
      else
        SETTINGS=$(find "$XILINX_ROOT" -maxdepth 3 -name "settings64.sh" -path "*/Vivado/*" 2>/dev/null | sort -V | tail -1)
      fi

      if [ -z "$SETTINGS" ] || [ ! -f "$SETTINGS" ]; then
        echo "ERROR: Vivado settings64.sh not found under $XILINX_ROOT"
        echo "       Set XILINX_ROOT or verify your installation in /opt/Xilinx"
        exit 1
      fi
      source "$SETTINGS"
      exec vivado "$@"
    '';
  };

  vitisFHS = pkgs.buildFHSEnv {
    name = "vitis";
    targetPkgs = vivadoPkgs;
    runScript = pkgs.writeScript "vitis-run" ''
      #!/bin/bash
      # If the first argument is an executable file or script, run it directly
      if [ $# -gt 0 ] && [ -f "$1" ] && [ -x "$1" ]; then
        exec -- "$@"
      fi

      XILINX_ROOT="''${XILINX_ROOT:-/opt/Xilinx}"
      if [ -f "$XILINX_ROOT/Vitis/settings64.sh" ]; then
        SETTINGS="$XILINX_ROOT/Vitis/settings64.sh"
      elif [ -f "$XILINX_ROOT/2026.1/Vitis/settings64.sh" ]; then
        SETTINGS="$XILINX_ROOT/2026.1/Vitis/settings64.sh"
      else
        SETTINGS=$(find "$XILINX_ROOT" -maxdepth 3 -path "*/Vitis/settings64.sh" 2>/dev/null | sort -V | tail -1)
      fi

      if [ -z "$SETTINGS" ] || [ ! -f "$SETTINGS" ]; then
        echo "ERROR: Vitis settings64.sh not found under $XILINX_ROOT"
        echo "       Set XILINX_ROOT or verify your installation in /opt/Xilinx"
        exit 1
      fi
      source "$SETTINGS"
      exec vitis "$@"
    '';
  };

  gowinFHS = pkgs.buildFHSEnv {
    name = "gowin-eda";
    targetPkgs = p: with p; [
      glibc glib gcc-unwrapped.lib
      libGL libx11 libxrender libxtst libxi
      libxext libxcb ncurses5 zlib
      coreutils bash which
    ];
    runScript = pkgs.writeScript "gowin-run" ''
      #!/bin/bash
      if [ $# -gt 0 ]; then
        exec "$@"
      fi
      GOWIN_ROOT="''${GOWIN_ROOT:-/opt/gowin}"
      if [ ! -d "$GOWIN_ROOT" ]; then
        echo "ERROR: Gowin EDA not found at $GOWIN_ROOT"
        echo "       To run the installer, use: gowin-eda <path-to-installer>"
        exit 1
      fi
      exec "$GOWIN_ROOT/IDE/bin/gw_ide"
    '';
  };

  iseFHS = pkgs.buildFHSEnv {
    name = "ise";
    targetPkgs = p: with p; [
      glibc glibc.dev glib gcc-unwrapped.lib
      libGL libGLU libx11 libxrender libxtst libxi
      libxext libxcb libxft libxcursor libxfixes
      libxcomposite libxscrnsaver motif
      libxt libxmu
      libSM libICE libXrandr
      libpng12 libxp
      gtk2 gtk3 gdk-pixbuf
      ncurses5 zlib freetype fontconfig
      coreutils bash which gnumake nettools procps
      p."libusb-compat-0_1" libusb1
      util-linux.lib
      libxcrypt-legacy
      perl python3
    ];
    runScript = pkgs.writeScript "ise-run" ''
      #!/bin/bash
      export _JAVA_AWT_WM_NONREPARENTING=1
      export GDK_BACKEND=x11
      COMPAT_DIR="/tmp/ise-compat-libs"
      mkdir -p "$COMPAT_DIR"
      for xm in /usr/lib64/libXm.so.4 /usr/lib/libXm.so.4 /lib64/libXm.so.4 /lib/libXm.so.4; do
        if [ -f "$xm" ]; then
          ln -sf "$xm" "$COMPAT_DIR/libXm.so.3"
          break
        fi
      done
      export LD_LIBRARY_PATH="$COMPAT_DIR:/lib:/usr/lib:/lib64:/usr/lib64''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      # Ensure Qt4 configuration exists for comfortable UI font scaling on HiDPI/1080p
      FONT_SIZE="''${ISE_FONT_SIZE:-9}"
      if [ -f "$HOME/.config/Trolltech.conf" ]; then
        if grep -q "^font=" "$HOME/.config/Trolltech.conf"; then
          [ -n "$ISE_FONT_SIZE" ] && sed -i "s/^font=.*/font=\"DejaVu Sans,$FONT_SIZE,-1,5,50,0,0,0,0,0\"/" "$HOME/.config/Trolltech.conf"
        else
          sed -i "/^\[Qt\]/a font=\"DejaVu Sans,$FONT_SIZE,-1,5,50,0,0,0,0,0\"\nfontPath=@Invalid()" "$HOME/.config/Trolltech.conf"
        fi
      else
        mkdir -p "$HOME/.config"
        cat <<EOF > "$HOME/.config/Trolltech.conf"
[Qt]
font="DejaVu Sans,$FONT_SIZE,-1,5,50,0,0,0,0,0"
fontPath=@Invalid()
EOF
      fi
      ISE_ROOT="''${ISE_ROOT:-/opt/Xilinx/14.7/ISE_DS}"
      if [ -f "$ISE_ROOT/settings64.sh" ]; then
        source "$ISE_ROOT/settings64.sh" "$ISE_ROOT" >/dev/null 2>&1
      elif [ -f "$ISE_ROOT/settings32.sh" ]; then
        source "$ISE_ROOT/settings32.sh" "$ISE_ROOT" >/dev/null 2>&1
      fi

      if [ $# -eq 0 ]; then
        exec ise
      elif [[ "$1" == -* ]]; then
        exec ise "$@"
      else
        exec "$@"
      fi
    '';
  };

  impactFHS = pkgs.buildFHSEnv {
    name = "impact";
    targetPkgs = p: with p; [
      glibc glibc.dev glib gcc-unwrapped.lib
      libGL libGLU libx11 libxrender libxtst libxi
      libxext libxcb libxft libxcursor libxfixes
      libxcomposite libxscrnsaver motif
      libxt libxmu
      libSM libICE libXrandr
      libpng12 libxp
      ncurses5 zlib freetype fontconfig
      coreutils bash which nettools procps
      p."libusb-compat-0_1" libusb1
      util-linux.lib
      libxcrypt-legacy
    ];
    runScript = pkgs.writeScript "impact-run" ''
      #!/bin/bash
      export _JAVA_AWT_WM_NONREPARENTING=1
      export GDK_BACKEND=x11
      COMPAT_DIR="/tmp/ise-compat-libs"
      mkdir -p "$COMPAT_DIR"
      for xm in /usr/lib64/libXm.so.4 /usr/lib/libXm.so.4 /lib64/libXm.so.4 /lib/libXm.so.4; do
        if [ -f "$xm" ]; then
          ln -sf "$xm" "$COMPAT_DIR/libXm.so.3"
          break
        fi
      done
      export LD_LIBRARY_PATH="$COMPAT_DIR:/lib:/usr/lib:/lib64:/usr/lib64''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      # Ensure Qt4 configuration exists for comfortable UI font scaling on HiDPI/1080p
      FONT_SIZE="''${ISE_FONT_SIZE:-9}"
      if [ -f "$HOME/.config/Trolltech.conf" ]; then
        if grep -q "^font=" "$HOME/.config/Trolltech.conf"; then
          [ -n "$ISE_FONT_SIZE" ] && sed -i "s/^font=.*/font=\"DejaVu Sans,$FONT_SIZE,-1,5,50,0,0,0,0,0\"/" "$HOME/.config/Trolltech.conf"
        else
          sed -i "/^\[Qt\]/a font=\"DejaVu Sans,$FONT_SIZE,-1,5,50,0,0,0,0,0\"\nfontPath=@Invalid()" "$HOME/.config/Trolltech.conf"
        fi
      else
        mkdir -p "$HOME/.config"
        cat <<EOF > "$HOME/.config/Trolltech.conf"
[Qt]
font="DejaVu Sans,$FONT_SIZE,-1,5,50,0,0,0,0,0"
fontPath=@Invalid()
EOF
      fi
      ISE_ROOT="''${ISE_ROOT:-/opt/Xilinx/14.7/ISE_DS}"
      if [ -f "$ISE_ROOT/settings64.sh" ]; then
        source "$ISE_ROOT/settings64.sh" "$ISE_ROOT" >/dev/null 2>&1
      elif [ -f "$ISE_ROOT/settings32.sh" ]; then
        source "$ISE_ROOT/settings32.sh" "$ISE_ROOT" >/dev/null 2>&1
      fi

      if [ $# -eq 0 ]; then
        exec impact
      elif [[ "$1" == -* ]]; then
        exec impact "$@"
      else
        exec "$@"
      fi
    '';
  };

  iseDesktopItem = pkgs.makeDesktopItem {
    name = "xilinx-ise";
    desktopName = "Xilinx ISE 14.7";
    comment = "Xilinx ISE WebPACK / Design Suite";
    exec = "ise";
    icon = "/opt/Xilinx/14.7/ISE_DS/ISE/data/images/pn-ise.png";
    categories = [ "Development" "Engineering" ];
    terminal = false;
  };

  impactDesktopItem = pkgs.makeDesktopItem {
    name = "xilinx-impact";
    desktopName = "Xilinx iMPACT";
    comment = "Xilinx JTAG Programming & Configuration Environment";
    exec = "impact";
    icon = "/opt/Xilinx/14.7/ISE_DS/ISE/data/images/impact.png";
    categories = [ "Development" "Engineering" ];
    terminal = false;
  };

  # ── RISC-V compatibility aliases ──────────────────────────────────────
  # Provides riscv32-unknown-elf-*, riscv64-unknown-elf-*, and
  # riscv-none-embed-* symlinks for build systems that expect those triplets.
  riscvCompatAliases = pkgs.runCommand "riscv-compat-aliases" { } ''
    mkdir -p $out/bin
    for f in ${pkgs.pkgsCross.riscv32-embedded.buildPackages.gcc}/bin/riscv32-none-elf-*; do
      base=$(basename "$f")
      ln -s "$f" "$out/bin/''${base/riscv32-none-elf/riscv32-unknown-elf}"
    done
    for f in ${pkgs.pkgsCross.riscv64-embedded.buildPackages.gcc}/bin/riscv64-none-elf-*; do
      base=$(basename "$f")
      ln -s "$f" "$out/bin/''${base/riscv64-none-elf/riscv64-unknown-elf}"
    done
    # Multiarch GDB aliases
    ln -s ${pkgs.gdb}/bin/gdb $out/bin/riscv32-none-elf-gdb
    ln -s ${pkgs.gdb}/bin/gdb $out/bin/riscv64-none-elf-gdb
    ln -s ${pkgs.gdb}/bin/gdb $out/bin/riscv-none-embed-gdb
  '';

in
{
  # ── nix-ld — run pre-compiled ELF binaries ────────────────────────────
  programs.nix-ld = {
    enable    = true;
    libraries = with pkgs; [
      glibc glib gcc-unwrapped.lib stdenv.cc.cc
      libGL libx11 libxrender zlib ncurses5
      openssl libxml2 libxslt
    ];
  };

  # ── System-wide FPGA & Hardware Packages ───────────────────────────────
  environment.systemPackages = with pkgs; [
    # Synthesis
    yosys            # open-source synthesis suite

    # Place & Route
    nextpnr           # next-generation place & route (iCE40, ECP5, Nexus)
    # nextpnr-xilinx  # experimental Xilinx support

    # Board support
    icestorm          # iCE40 toolchain (programming + bit-stream tools)
    trellis           # ECP5 toolchain

    # HDL simulation
    ghdl              # VHDL simulator
    verilator         # Verilog/SystemVerilog simulator
    iverilog          # Icarus Verilog

    # Formal verification
    sby               # formal verification front-end (formerly symbiyosys)
    yices             # SMT solver (used by sby)
    z3                # SMT solver

    # Waveform viewer
    gtkwave

    # Programming / JTAG
    openfpgaloader    # universal FPGA programmer (Xilinx, Gowin, Lattice, …)
    openocd           # JTAG / SWD debugger

    # HDL development
    python313Packages.cocotb      # HDL cosimulation (python 3.13)
    python3Packages.migen         # Python-based HDL
    python3Packages.amaranth      # Amaranth HDL

    # RISC-V Cross Toolchains (RV32 / RV64 bare-metal & embedded)
    pkgsCross.riscv32-embedded.buildPackages.gcc       # riscv32-none-elf-gcc, g++, as, ld, etc.
    pkgsCross.riscv32-embedded.buildPackages.binutils  # riscv32-none-elf-objcopy, objdump, size, strip, etc.
    pkgsCross.riscv64-embedded.buildPackages.gcc       # riscv64-none-elf-gcc, g++, as, ld, etc.
    pkgsCross.riscv64-embedded.buildPackages.binutils  # riscv64-none-elf-objcopy, objdump, size, strip, etc.
    gdb                                                # Multiarch GDB (supports riscv32/riscv64)
    riscvCompatAliases                                 # riscv{32,64}-unknown-elf-*, riscv-none-embed-*, and gdb aliases

    # Hardware programming tools
    xc3sprog                                           # Spartan-3/3E/6 and CPLD programmer
    fxload                                             # Cypress FX2 USB microcontroller firmware loader

    # FHS wrappers for proprietary tools
    vivadoFHS
    vitisFHS
    gowinFHS
    iseFHS
    impactFHS
    iseDesktopItem
    impactDesktopItem
  ];

  # ── udev rules for FPGA programmers ──────────────────────────────────
  services.udev.extraRules = ''
    # Xilinx Cypress FX2 (on-board USB JTAG) — Stage 1: load firmware
    # fxload >= 1.0 uses -p bus,addr instead of legacy -D /dev/... flag
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="03fd", ATTRS{idProduct}=="0007", RUN+="${pkgs.fxload}/bin/fxload -v -t fx2 -i /opt/Xilinx/14.7/ISE_DS/ISE/bin/lin64/xusb_emb.hex -p $env{BUSNUM},$env{DEVNUM}"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="03fd", ATTRS{idProduct}=="0009", RUN+="${pkgs.fxload}/bin/fxload -v -t fx2 -i /opt/Xilinx/14.7/ISE_DS/ISE/bin/lin64/xusb_emb.hex -p $env{BUSNUM},$env{DEVNUM}"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="03fd", ATTRS{idProduct}=="000b", RUN+="${pkgs.fxload}/bin/fxload -v -t fx2 -i /opt/Xilinx/14.7/ISE_DS/ISE/bin/lin64/xusb_emb.hex -p $env{BUSNUM},$env{DEVNUM}"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="03fd", ATTRS{idProduct}=="000d", RUN+="${pkgs.fxload}/bin/fxload -v -t fx2 -i /opt/Xilinx/14.7/ISE_DS/ISE/bin/lin64/xusb_emb.hex -p $env{BUSNUM},$env{DEVNUM}"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="03fd", ATTRS{idProduct}=="000f", RUN+="${pkgs.fxload}/bin/fxload -v -t fx2 -i /opt/Xilinx/14.7/ISE_DS/ISE/bin/lin64/xusb_emb.hex -p $env{BUSNUM},$env{DEVNUM}"
    # Stage 2: Initialized Cypress FX2 / Xilinx Platform Cable USB (re-enumerates as 03fd:0008)
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="03fd", ATTRS{idProduct}=="0008", MODE="0666", GROUP="plugdev", TAG+="uaccess"

    # Digilent Adept USB devices (JTAG cables & boards)
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="1443", MODE="0666", GROUP="plugdev", TAG+="uaccess"

    # Xilinx USB cable (Platform Cable USB II — FTDI-based)
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6011", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    # Fallback: any remaining 03fd device (after firmware load)
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="03fd", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    # Gowin Tang Nano / Tang Primer (WCH CH347)
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="55dd", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="55de", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    # Digilent JTAG (Arty, Nexys, etc.)
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    # OpenOCD generic FTDI
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE="0660", GROUP="plugdev", TAG+="uaccess"
  '';


  # ── Environment variables ─────────────────────────────────────────────
  environment.sessionVariables = {
    XILINX_ROOT   = "/opt/Xilinx";     # point to your Vivado install
    GOWIN_ROOT     = "/opt/gowin";      # point to your Gowin EDA install
  };
}
