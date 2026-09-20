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
      libGL libGLU libx11 libxrender libxtst libxi
      libxext libxcb libxft libxcursor libxfixes
      libxcomposite motif
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
      libGL libx11 libxrender libxtst libxi
      libxext libxcb ncurses5 zlib
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

  # ── RISC-V compatibility aliases ──────────────────────────────────────
  # Provides riscv32-unknown-elf-*, riscv64-unknown-elf-*, and
  # riscv-none-embed-* symlinks for build systems that expect those triplets.
  riscvCompatAliases = pkgs.runCommand "riscv-compat-aliases" { } ''
    mkdir -p $out/bin
    for f in ${pkgs.pkgsCross.riscv32-embedded.buildPackages.gcc}/bin/riscv32-none-elf-*; do
      base=$(basename "$f")
      ln -s "$f" "$out/bin/''${base/riscv32-none-elf/riscv32-unknown-elf}"
      ln -s "$f" "$out/bin/''${base/riscv32-none-elf/riscv-none-embed}"
    done
    for f in ${pkgs.pkgsCross.riscv64-embedded.buildPackages.gcc}/bin/riscv64-none-elf-*; do
      base=$(basename "$f")
      ln -s "$f" "$out/bin/''${base/riscv64-none-elf/riscv64-unknown-elf}"
    done
    # Multiarch GDB aliases
    ln -s ${pkgs.gdb}/bin/gdb $out/bin/riscv32-none-elf-gdb
    ln -s ${pkgs.gdb}/bin/gdb $out/bin/riscv32-unknown-elf-gdb
    ln -s ${pkgs.gdb}/bin/gdb $out/bin/riscv64-none-elf-gdb
    ln -s ${pkgs.gdb}/bin/gdb $out/bin/riscv64-unknown-elf-gdb
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

  # ── OSS FPGA toolchain ────────────────────────────────────────────────
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
