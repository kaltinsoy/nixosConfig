{ pkgs, lib, ... }:

let
  # ── FHS environment for proprietary EDA tools ─────────────────────────
  # Vivado and Gowin EDA ship bundled binaries that expect a "normal" Linux
  # filesystem layout. buildFHSEnv creates a chroot that satisfies that.

  vivadoFHS = pkgs.buildFHSEnv {
    name = "vivado";
    targetPkgs = p: with p; [
      # C/C++ runtime
      glibc glibc.dev glib gcc-unwrapped.lib
      # Graphics
      libGL libGLU xorg.libX11 xorg.libXrender xorg.libXtst xorg.libXi
      xorg.libXext xorg.libxcb xorg.libXft xorg.libXcursor xorg.libXfixes
      xorg.libXcomposite motif
      # Misc
      ncurses5 zlib freetype fontconfig
      coreutils bash which
      # Java (Vivado 2022+ bundles its own, but some versions need system Java)
      temurin-bin-17
    ];
    runScript = ''
      #!/bin/bash
      XILINX_ROOT="''${XILINX_ROOT:-/opt/Xilinx}"
      if [ ! -d "$XILINX_ROOT/Vivado" ]; then
        echo "ERROR: Xilinx tools not found at $XILINX_ROOT"
        echo "       Set XILINX_ROOT or install Vivado to /opt/Xilinx"
        exit 1
      fi
      # Source Vivado settings
      source "$XILINX_ROOT/Vivado/$(ls "$XILINX_ROOT/Vivado" | sort -V | tail -1)/settings64.sh"
      exec vivado "$@"
    '';
  };

  gowinFHS = pkgs.buildFHSEnv {
    name = "gowin-eda";
    targetPkgs = p: with p; [
      glibc glib gcc-unwrapped.lib
      libGL xorg.libX11 xorg.libXrender xorg.libXtst xorg.libXi
      xorg.libXext xorg.libxcb ncurses5 zlib
      coreutils bash which
    ];
    runScript = ''
      #!/bin/bash
      GOWIN_ROOT="''${GOWIN_ROOT:-/opt/gowin}"
      if [ ! -d "$GOWIN_ROOT" ]; then
        echo "ERROR: Gowin EDA not found at $GOWIN_ROOT"
        echo "       Set GOWIN_ROOT or install Gowin EDA to /opt/gowin"
        exit 1
      fi
      exec "$GOWIN_ROOT/IDE/bin/gw_ide" "$@"
    '';
  };

in
{
  # ── nix-ld — run pre-compiled ELF binaries ────────────────────────────
  programs.nix-ld = {
    enable    = true;
    libraries = with pkgs; [
      glibc glib gcc-unwrapped.lib stdenv.cc.cc
      libGL xorg.libX11 xorg.libXrender zlib ncurses5
      openssl libxml2 libxslt
    ];
  };

  # ── OSS FPGA toolchain ────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Synthesis
    yosys            # open-source synthesis suite
    yosys-synlig     # SystemVerilog frontend for yosys

    # Place & Route
    nextpnr           # next-generation place & route (iCE40, ECP5, Nexus)
    # nextpnr-xilinx  # experimental Xilinx support

    # Board support
    icestorm          # iCE40 toolchain (programming + bit-stream tools)
    trellis           # ECP5 toolchain
    prjtrellis        # ECP5 project

    # HDL simulation
    ghdl              # VHDL simulator
    verilator         # Verilog/SystemVerilog simulator
    iverilog          # Icarus Verilog

    # Formal verification
    symbiyosys        # formal verification front-end
    yices             # SMT solver (used by symbiyosys)
    z3                # SMT solver

    # Waveform viewer
    gtkwave

    # Programming / JTAG
    openFPGALoader    # universal FPGA programmer (Xilinx, Gowin, Lattice, …)
    openocd           # JTAG / SWD debugger

    # HDL development
    python3Packages.cocotb        # HDL cosimulation
    python3Packages.migen         # Python-based HDL
    python3Packages.amaranth      # Amaranth HDL

    # FHS wrappers for proprietary tools
    vivadoFHS
    gowinFHS
  ];

  # ── udev rules for FPGA programmers ──────────────────────────────────
  services.udev.extraRules = ''
    # Xilinx USB cable (Platform Cable USB II)
    ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6011", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    # Xilinx FTDI-based cables
    ATTRS{idVendor}=="03fd", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    # Gowin Tang Nano / Tang Primer (WCH CH347)
    ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="55dd", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="55de", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    # Digilent JTAG (Arty, Nexys, etc.)
    ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    # OpenOCD generic FTDI
    ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE="0660", GROUP="plugdev", TAG+="uaccess"
  '';

  # ── Environment variables ─────────────────────────────────────────────
  environment.sessionVariables = {
    XILINX_ROOT   = "/opt/Xilinx";     # point to your Vivado install
    GOWIN_ROOT     = "/opt/gowin";      # point to your Gowin EDA install
  };
}
