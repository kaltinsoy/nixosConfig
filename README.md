# ThinkPad T480s — NixOS Workstation Configuration

A modular, reproducible, production-ready NixOS flake configuration tailored specifically for the **Lenovo ThinkPad T480s (`sumatra`)** running **GNOME on Wayland**.

Engineered for:
- **FPGA Development & Hardware Design**: Open-source tools (Yosys, Nextpnr, Verilator) + full FHS wrappers for AMD/Xilinx Vivado 2026.1, Vitis 2026.1, and Gowin EDA.
- **Cybersecurity & Penetration Testing**: Distrobox / VM-isolated ParrotOS lab keeping the NixOS host clean.
- **Virtualization & Container Labs**: QEMU/KVM, UEFI/OVMF, swtpm, Docker, Distrobox, Looking Glass.
- **Gaming & Media**: Steam, Gamescope, GameMode, Protontricks, Spicetify.
- **High-Performance Daily Driving**: NvChad (Neovim), Zen Browser, Bitwarden, Anki, Nextcloud, and tailored ThinkPad hardware tuning.

---

## Quick Command Reference

Your system includes custom shell binaries and aliases configured in `$PATH`:

| Command | Full Action | When to Use |
| :--- | :--- | :--- |
| **`nrs`** | `sudo nixos-rebuild switch --flake ~/nixos-config#sumatra` | **Apply config changes** (instant, safe, does not change pinned package versions). |
| **`nrb`** | `sudo nixos-rebuild boot --flake ~/nixos-config#sumatra` | Build and set as default for next boot without switching immediately. |
| **`nrt`** | `sudo nixos-rebuild test --flake ~/nixos-config#sumatra` | Test a configuration in the current session without adding a bootloader entry. |
| **`nfu`** | `nix flake update --flake ~/nixos-config` | **Update `flake.lock`** to fetch latest package versions from upstream. |
| **`nclean`** / **`ncg`** | Profile GC + System GC + Bootloader refresh + Store optimise | **Reclaim disk space** (run occasionally, e.g. once a month; **not** after every update). |

---

## File Structure

```
nixos-config/
├── flake.nix                       # Flake inputs (nixpkgs, home-manager, nixos-hardware, zen-browser, spicetify, 06cb-009a)
├── flake.lock                      # Pinned dependency revisions (guarantees 100% reproducible builds)
├── hosts/
│   └── default/
│       ├── configuration.nix       # Base host configuration, system packages, users, & nrs/nclean scripts
│       └── hardware-configuration.nix # T480s hardware configuration (Intel 8th-gen, NVMe SSD, graphics)
├── modules/
│   ├── system/
│   │   ├── boot.nix                # systemd-boot, latest Linux kernel, IOMMU, tmpfs
│   │   ├── networking.nix          # NetworkManager, WireGuard, firewall, SSH, Avahi
│   │   ├── locale.nix              # Timezone (Europe/Istanbul), UTF-8, Turkish Q keyboard
│   │   ├── security.nix            # PAM (06cb:009a fingerprint + Howdy face unlock), sudo, polkit
│   │   └── services.nix            # PipeWire audio, Bluetooth, CUPS printing, fwupd, Flatpak
│   ├── desktop/
│   │   ├── gnome.nix               # GNOME Wayland desktop, GDM, core utilities, bloat exclusion
│   │   ├── fonts.nix               # Nerd Fonts (JetBrainsMono, FiraCode), Inter, Noto Color Emoji, grayscale AA
│   │   └── steam.nix               # Steam, Gamescope session, GameMode daemon, Protontricks, firewall rules
│   ├── hardware/
│   │   └── lenovo.nix              # TLP power & battery thresholds, throttled undervolt, thinkfan, WWAN, 06cb:009a
│   ├── virt/
│   │   └── qemu-kvm.nix            # Libvirt/QEMU, UEFI/OVMF, swtpm, Docker, Distrobox, Looking Glass
│   ├── fpga/
│   │   └── fpga.nix                # OSS FPGA suite (Yosys, Nextpnr, Verilator), Vivado & Vitis & Gowin FHS wrappers
│   └── security-tools/
│       └── cybersec.nix            # Containerized / VM-isolated ParrotOS security research lab
└── home/
    ├── home.nix                    # Home Manager root: packages (Anki, Cloudflared, EasyEffects), Git, SSH, aliases
    ├── neovim/
    │   └── neovim.nix              # NvChad (pinned starter) + LSP servers + formatters (clang-format, shfmt, ruff)
    ├── apps/
    │   ├── browsers.nix            # Zen Browser, hardened Firefox profile, Tor Browser
    │   └── media.nix               # Spicetify (Catppuccin Mocha theme + Spotify extensions)
    └── gnome-extensions/
        └── extensions.nix          # dconf declarative settings (150% volume over-amplification, grayscale font AA)
```

---

## Complete Application & Tool Directory

### 1. Core Desktop & Terminal Emulators

| Application | Purpose |
| :--- | :--- |
| **GNOME 48 (Wayland)** | Native Wayland desktop with 125% fractional scaling and grayscale antialiasing. |
| **Ghostty & Alacritty** | Blazing-fast GPU-accelerated terminals with native Wayland support and tabs. |
| **Tmux & Zellij** | Terminal multiplexers for persistent, detachable sessions and split panes. |
| **Fastfetch & Btop** | Instant system information splash and modern interactive resource monitor. |
| **Bat, Eza, Ripgrep, Fd** | Modern CLI replacements for `cat`, `ls`, `grep`, and `find`. |
| **Delta & Difftastic** | Syntax-highlighted and AST-aware diff pagers for Git code review. |

### 2. Editor & IDE (NvChad Neovim)

| Component | Purpose |
| :--- | :--- |
| **Neovim (NvChad)** | Extensible modal text editor configured with the Catppuccin Mocha theme. |
| **LSP Servers** | `nixd` (Nix), `pyright` (Python), `clang-tools` (C/C++), `rust-analyzer` (Rust), `typescript-language-server` (TS/JS), `bash-language-server` (Bash), `yaml-language-server` (YAML), `taplo` (TOML), `marksman` (Markdown). |
| **Formatters & Linters** | `nixfmt`, `clang-format`, `shfmt`, `shellcheck`, `stylua`, `black`, `isort`, `ruff`, `rustfmt`, `prettier`, `verilator`. |

### 3. Web Browsers, Productivity & Daily Drivers

| Application | Purpose |
| :--- | :--- |
| **Zen Browser** | Fast, privacy-centric Firefox fork featuring vertical tabs and split workspaces. |
| **Firefox & Tor Browser** | Hardened secondary browser profile and anonymous onion-routed browsing. |
| **Bitwarden Desktop & CLI** | Open-source password manager with biometric unlock integration and `bw` CLI. |
| **Anki** | Spaced repetition flashcard app for learning and memorization. |
| **Obsidian & QOwnNotes** | Markdown note-taking suites with Nextcloud synchronization. |
| **Xournal++** | Handwriting, PDF annotation, and sketching tool. |
| **LibreOffice** | Full office productivity suite (Writer, Calc, Impress). |
| **GIMP & Inkscape** | Raster image editing and vector graphic design. |
| **MPV & VLC** | Ultra-efficient video and media players. |
| **Spotify (Spicetify)** | Custom Spotify client with Catppuccin Mocha theme and extensions. |
| **Vesktop & Element** | Discord client (with Vencord) and encrypted Matrix messaging client. |
| **Cloudflared** | Cloudflare Tunnel daemon and SSH Access proxy (`*.anilkoray.tr`). |

### 4. Gaming & Graphics

| Component | Purpose |
| :--- | :--- |
| **Steam** | 32-bit graphics support, controller hardware udev rules, and remote play firewall ports. |
| **GameMode** | Feral Interactive daemon optimizing CPU governor and scheduler priority while gaming. |
| **Gamescope** | Micro-compositor session for resolution scaling, HDR, and window sandboxing. |
| **Protontricks & Winetricks** | Wine/Proton prefix utility for installing Windows game dependencies. |

### 5. Audio Enhancement (ThinkPad T480s Speakers)

| Component | Purpose |
| :--- | :--- |
| **150% Over-amplification** | Enabled in GNOME settings to bypass the quiet 100% volume ceiling on the ALC257 codec. |
| **EasyEffects** | Installed with tailored laptop DSP presets (`~/.local/share/easyeffects/output/`):<br>• **`Laptop`** (Digitalone1 LoudnessEqualizer): Upward compressor, multiband EQ, and limiter to boost clarity and vocal presence without distortion.<br>• **`Loudness+Autogain`**: Bass enhancer + autogain + compressor for extra loudness.<br>*(Autostart daemon is disabled; launch manually with `easyeffects` when needed).* |

### 6. FPGA Development & Hardware Design

| Tool | Purpose |
| :--- | :--- |
| **Vivado 2026.1 (FHS)** | AMD / Xilinx Vivado ML Standard installed in `/opt/Xilinx/2026.1/Vivado`. Runs in a dedicated bubblewrap FHS container with full graphics, X11 (`libXtst`, `libXi`), `graphviz`, and legacy libraries. Launch via `vivado`. |
| **Vitis 2026.1 (FHS)** | Embedded development suite in `/opt/Xilinx/2026.1/Vitis`. Launch via `vitis`. |
| **Gowin EDA (FHS)** | FHS sandbox for Gowin IDE (`/opt/gowin`). Launch via `gowin-eda`. |
| **Yosys & Nextpnr** | Open-source synthesis and place-and-route suite (iCE40, ECP5, Nexus). |
| **GHDL, Verilator, Iverilog** | VHDL simulator, high-speed C++ Verilog simulator, and Icarus Verilog compiler. |
| **Sby, Yices, Z3** | Formal verification suite with SMT solvers. |
| **GTKWave** | Waveform viewer for inspecting VCD simulation files. |
| **OpenFPGALoader & OpenOCD** | Universal FPGA programmer (Xilinx, Gowin, Digilent) and JTAG debugger. |
| **RISC-V Toolchains** | Bare-metal `riscv32-none-elf` and `riscv64-none-elf` GCC, binutils, and multiarch GDB. |

### 7. Virtualization & Container Labs

| Tool | Purpose |
| :--- | :--- |
| **QEMU / KVM & Virt-Manager** | Hardware-accelerated hypervisor with desktop management GUI. |
| **OVMF (UEFI) & swtpm** | Software TPM 2.0 and UEFI firmware (enables Windows 11 VMs). |
| **Docker & Docker Compose** | Container runtime and orchestration platform. |
| **Distrobox** | Run any Linux distribution (Ubuntu, Arch, Fedora, Kali) with native GUI and home integration. |
| **Looking Glass Client** | Ultra-low latency KVM frame-relay display client for GPU passthrough. |

---

## Hardware Management Reference

### 1. Fingerprint Reader (Synaptics `06cb:009a`)
The T480s sensor is a Match-on-Host device driven by the `nixos-06cb-009a-fingerprint-sensor` flake with native `libfprint-tod` PAM integration.

- **PAM Anti-Freeze Protection**: PAM is configured with `max-tries=1` and `timeout=10` in [security.nix](file:///home/koray/nixos-config/modules/system/security.nix). Because the `06cb:009a` hardware controller cannot handle immediate back-to-back re-activation without locking up, `max-tries=1` ensures that a failed scan immediately drops to password authentication without freezing the terminal.
- **Enrolling fingers**:
  ```bash
  fprintd-enroll
  fprintd-verify
  ```

### 2. Facial Recognition (Howdy)
Configured using the 720p HD Integrated Camera (`/dev/v4l/by-path/pci-0000:00:14.0-usb-0:8:1.0-video-index0` / `/dev/video2`).

- **Enroll your face**:
  ```bash
  sudo howdy add
  sudo howdy test
  sudo howdy list
  ```
- *Note*: `linux-enable-ir-emitter` is disabled because the T480s 160x120 IR sensor cannot stream frames under Linux UVC and triggers camera LED latching.

### 3. Battery Management & Calibration (TLP)
The single internal battery (`BAT0`) is configured in **Conservation Mode** (starts charging below 75%, stops at 80%) in [lenovo.nix](file:///home/koray/nixos-config/modules/hardware/lenovo.nix).

- **Check Battery Health & Status**:
  ```bash
  sudo tlp-stat -b
  ```
- **New Battery Calibration**:
  Plug in the AC charger (keep it connected) and run:
  ```bash
  sudo tlp recalibrate BAT0
  ```
  *(TLP will charge to 100%, use the ThinkPad ACPI circuit to discharge to ~0%, and recharge to 100% uninterrupted, automatically restoring 75%/80% thresholds).*
- **Force One-Time Full Charge (100%)**:
  ```bash
  sudo tlp fullcharge BAT0
  ```

### 4. CPU Undervolting & Thermals (`throttled` + `thinkfan`)
- **Undervolting**: Configured in [lenovo.nix](file:///home/koray/nixos-config/modules/hardware/lenovo.nix) (`-100mV` Core/Cache on AC, `-80mV` on Battery) to eliminate 8th-gen thermal throttling.
- **Fan Control**: `thinkfan` controls fan speeds via ACPI temperature sensor curves.

---

## Updating & Maintenance Guide

### 1. Normal Day-to-Day Workflow
When you edit files in `~/nixos-config` (e.g. adding packages, tweaking dotfiles):
```bash
nrs
```

### 2. Upgrading System Packages (Weekly / Monthly)
To update the flake lockfile and pull down newer packages from upstream:
```bash
nfu && nrs
```

### 3. Reclaiming Disk Space (Occasional)
To delete old generations, clean the Nix store, and update bootloader entries:
```bash
nclean
# (or: ncg)
```
> [!IMPORTANT]
> Do **not** run `nclean` after every update. Keeping previous generations preserves your ability to roll back if a new kernel or package update ever introduces a bug.

### 4. Rolling Back
If an update ever breaks anything:
```bash
# Instant rollback in the terminal:
sudo nixos-rebuild switch --rollback

# Or reboot and pick any previous working generation from the systemd-boot menu!
```
