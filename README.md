# ThinkPad T480s — NixOS Workstation Configuration

A modular, production-ready NixOS flake configuration tailored for the **Lenovo ThinkPad T480s** running **GNOME on Wayland**.

Engineered for:
- **Cybersecurity Research & Penetration Testing**
- **FPGA Development & Hardware Design** (Open-source tools + Vivado/Gowin FHS wrappers)
- **Virtualization & Container Labs** (QEMU/KVM, Docker, Distrobox)
- **High-Performance Daily Driving** (NvChad, Zen Browser, Bitwarden, polished GNOME desktop)

---

## Quick Start

```bash
# 1. Clone repository
git clone <this-repo> ~/nixos-config
cd ~/nixos-config

# 2. Generate actual hardware configuration (if setting up a fresh install)
sudo nixos-generate-config --show-hardware-config > hosts/default/hardware-configuration.nix

# 3. Apply the system configuration (hostname: sumatra)
sudo nixos-rebuild switch --flake ~/nixos-config#sumatra
```

---

## File Structure

```
nixos-config/
├── flake.nix                       # Flake inputs (nixpkgs, home-manager, nixos-hardware, zen-browser, spicetify)
├── hosts/
│   └── default/
│       ├── configuration.nix       # Base host configuration, system packages & users
│       └── hardware-configuration.nix # T480s hardware configuration (Intel CPU, NVMe, graphics)
├── modules/
│   ├── system/
│   │   ├── boot.nix                # systemd-boot, latest Linux kernel, IOMMU, tmpfs
│   │   ├── networking.nix          # NetworkManager, WireGuard, firewall, SSH, Avahi
│   │   ├── locale.nix              # Timezone (Europe/Istanbul), UTF-8, Turkish Q keyboard
│   │   ├── security.nix            # PAM (fingerprint authentication), sudo, polkit, sysctl
│   │   └── services.nix            # PipeWire audio, Bluetooth, CUPS printing, fwupd, Flatpak
│   ├── desktop/
│   │   ├── gnome.nix               # GNOME Wayland desktop, GDM, core utilities, bloat exclusion
│   │   └── fonts.nix               # Nerd Fonts (JetBrainsMono, FiraCode), Inter, Noto Color Emoji
│   ├── hardware/
│   │   └── lenovo.nix              # TLP power management, throttled undervolt, thinkfan, fprintd, WWAN
│   ├── virt/
│   │   └── qemu-kvm.nix            # Libvirt/QEMU, UEFI/OVMF, swtpm, Docker, Distrobox, Looking Glass
│   ├── fpga/
│   │   └── fpga.nix                # OSS FPGA suite (Yosys, Nextpnr, Verilator), Vivado & Gowin FHS wrappers
│   └── security-tools/
│       └── cybersec.nix            # Penetration testing, RE, binary exploitation & forensics suite
└── home/
    ├── home.nix                    # Home Manager root: desktop apps, Git, SSH, pointers & themes
    ├── neovim/
    │   └── neovim.nix              # NvChad (pinned starter) + LSP servers + formatters + linters
    ├── apps/
    │   ├── browsers.nix            # Zen Browser, hardened Firefox profile, Tor Browser
    │   └── media.nix               # Spicetify (Catppuccin Mocha theme + Spotify extensions)
    └── gnome-extensions/
        └── extensions.nix          # dconf declarative settings for 14 GNOME Shell extensions
```

---

## Complete Application & Tool Directory

Here is a detailed breakdown of every application installed in this system and its exact role:

### 1. Core Desktop & Terminal Emulators

| Application | Purpose |
|---|---|
| **GNOME 48 (Wayland)** | Clean, modern desktop environment with full Wayland session and fractional scaling. |
| **Ghostty** | Ultra-fast, GPU-accelerated terminal emulator with native Wayland support and tabs. |
| **Alacritty** | Minimalist, blazing-fast GPU terminal emulator used as a lightweight fallback. |
| **Tmux & Zellij** | Terminal multiplexers for session persistence, split panes, and detachable workspaces. |
| **Fastfetch & Btop** | Fast system info splash tool and modern interactive terminal resource monitor. |
| **Bat & Eza** | Modern replacements for `cat` (with syntax highlighting) and `ls` (with tree/icons). |
| **Ripgrep (`rg`) & Fd** | High-performance search tools replacing `grep` and `find`. |
| **Delta & Difftastic** | Structural syntax-highlighting pagers for Git diffs and code review. |

### 2. Editor & IDE (NvChad Neovim)

| Component | Purpose |
|---|---|
| **Neovim (NvChad)** | Fast, extensible modal text editor configured with the Catppuccin Mocha theme. |
| **LSP Servers** | In-editor autocompletion and diagnostics: `nixd` (Nix), `pyright` (Python), `clang-tools` (C/C++), `rust-analyzer` (Rust), `typescript-language-server` (TS/JS), `bash-language-server` (Bash), `yaml-language-server` (YAML), `taplo` (TOML), `marksman` (Markdown). |
| **Linters & Formatters** | Automatic code formatting on save: `nixfmt` (Nix), `stylua` (Lua), `black` & `isort` (Python), `ruff` (Python linter), `rustfmt` (Rust), `prettier` (Web/JSON), `verilator` (Verilog/SystemVerilog linting). |

### 3. Web Browsers & Daily Drivers

| Application | Purpose |
|---|---|
| **Zen Browser** | Fast, privacy-centric Firefox fork featuring vertical tabs and split-view workspaces. |
| **Firefox** | Hardened secondary browser with strict tracking protection and telemetry disabled. |
| **Tor Browser** | Anonymous web browsing routing traffic through the onion network. |
| **Bitwarden (`bitwarden-desktop` + `bitwarden-cli`)** | Open-source password manager with desktop app and terminal CLI (`bw`). |
| **Obsidian** | Markdown knowledge base and note-taking application. |
| **LibreOffice** | Complete office productivity suite (Writer, Calc, Impress). |
| **GIMP & Inkscape** | Raster image editor and vector graphics design application. |
| **MPV & VLC** | High-performance video and media players with broad codec support. |
| **Spotify (Spicetify)** | Spotify client customized with Catppuccin Mocha theme, ad-block, and lyrics extensions. |
| **Vesktop & Element** | Discord client (with Vencord plugin) and Matrix encrypted messaging client. |
| **Syncthing & Rclone** | Continuous peer-to-peer file synchronization and multi-cloud sync CLI. |

### 4. Virtualization & Container Labs

| Tool | Purpose |
|---|---|
| **QEMU / KVM** | Hardware-accelerated hypervisor for near-native VM performance. |
| **Virt-Manager** | Desktop GUI for creating, configuring, and managing KVM virtual machines. |
| **OVMF (UEFI) & swtpm** | UEFI firmware and software TPM 2.0 emulation (enables running Windows 11 VMs). |
| **Docker & Docker Compose** | Container engine and multi-container orchestration platform. |
| **Distrobox** | Run any Linux distribution (Ubuntu, Arch, Fedora, Kali) inside a container with full GUI and home directory integration. |
| **Lazydocker & Ctop** | Interactive terminal UIs for managing Docker containers, images, and resource usage. |
| **Looking Glass Client** | Ultra-low latency KVM frame-relay display client for GPU passthrough setups. |

### 5. Cybersecurity & Penetration Testing

#### Network Reconnaissance & Traffic Analysis
| Tool | Purpose |
|---|---|
| **Nmap, Masscan, Rustscan** | Comprehensive port scanners ranging from fast network discovery to deep service enumeration. |
| **Wireshark, Tshark, Termshark** | Packet capture and protocol analyzers across GUI, CLI, and TUI interfaces. |
| **Mitmproxy** | Interactive SSL/TLS-capable intercepting HTTP proxy for debugging and pentesting. |
| **Bettercap & Ettercap** | Frameworks for network reconnaissance, ARP spoofing, and Man-in-the-Middle testing. |
| **Tcpdump & Tcpflow** | Network traffic packet capture and TCP stream reconstruction tools. |

#### Web Application Pentesting
| Tool | Purpose |
|---|---|
| **Burp Suite** | Leading web vulnerability scanner and proxy framework. |
| **SQLmap** | Automated SQL injection detection and database takeover tool. |
| **FFuF & Gobuster & Feroxbuster** | High-speed web directory, DNS, and virtual-host fuzzers. |
| **Nikto & Wfuzz** | Web server vulnerability scanner and flexible web application fuzzer. |

#### Password Recovery & Exploitation
| Tool | Purpose |
|---|---|
| **THC-Hydra & Medusa** | Fast network login brute-force tools supporting SSH, FTP, HTTP, RDP, and more. |
| **John the Ripper & Hashcat** | World-class offline password hash crackers utilizing CPU and GPU acceleration. |
| **Crunch & Wordlists** | Custom wordlist generator and curated security wordlists (including RockYou). |
| **Metasploit Framework** | Industry-standard penetration testing and exploit development platform. |

#### Reverse Engineering & Binary Exploitation
| Tool | Purpose |
|---|---|
| **Ghidra** | NSA's software reverse engineering suite with decompiler and disassembly. |
| **Radare2 & Iaito** | Command-line reverse engineering framework and its official GUI frontend. |
| **GDB & Pwntools** | GNU debugger and Python library dedicated to rapid exploit prototyping. |
| **Binwalk** | Firmware analysis tool for extracting embedded filesystem images. |
| **ImHex & Hexyl** | Advanced interactive hex editor and colored terminal hex viewer. |
| **Checksec & Yara** | Binary mitigation checker (ASLR, NX, PIE, Canaries) and pattern-matching engine. |

#### Digital Forensics & OSINT
| Tool | Purpose |
|---|---|
| **Volatility 3** | Advanced memory forensics framework for analyzing RAM dumps. |
| **Autopsy & Sleuthkit** | Digital forensics platform and disk image investigation library. |
| **Bulk Extractor & Foremost** | High-speed data carving tools for recovering deleted files from raw disk images. |
| **Maltego, TheHarvester, Amass** | Open-source intelligence (OSINT) mapping and attack surface reconnaissance. |

#### Privacy & Tunneling
| Tool | Purpose |
|---|---|
| **WireGuard & `wireguard-tools`** | Modern, fast VPN protocol with full GNOME Settings GUI integration (import `.conf` files). |
| **OpenVPN & OpenConnect** | Enterprise VPN clients integrated directly into NetworkManager. |
| **Tor, Torsocks, OnionShare** | Anonymity network routing, application torification, and secure file sharing. |
| **Proxychains-NG** | Forces any TCP connection through user-defined SOCKS4/5 or HTTP proxies. |
| **Age, Steghide, Stegseek** | Modern encryption tool and steganography detection/cracking utilities. |

### 6. FPGA Development & Hardware Design

| Tool | Purpose |
|---|---|
| **Yosys** | Open-source synthesis suite for Verilog and SystemVerilog. |
| **Nextpnr** | Timing-driven place-and-route tool supporting iCE40, ECP5, and Nexus FPGAs. |
| **Icestorm & Trellis** | Open-source bitstream generation and documentation for Lattice FPGAs. |
| **GHDL, Verilator, Iverilog** | VHDL simulator, high-speed C++ Verilog simulator, and Icarus Verilog compiler. |
| **Sby (SymbiYosys), Yices, Z3** | Formal verification frontend paired with SMT solvers for hardware assertion proofs. |
| **GTKWave** | Graphical waveform viewer for inspecting VCD simulation dump files. |
| **OpenFPGALoader & OpenOCD** | Universal programmer for FPGA boards (Xilinx, Gowin, Digilent) and JTAG debuggers. |
| **Cocotb, Migen, Amaranth** | Python-based HDL cosimulation testbenches and modern hardware description languages. |
| **Vivado FHS Wrapper** | Bubblewrap/chroot environment allowing proprietary Xilinx Vivado to run seamlessly on NixOS. |
| **Gowin EDA FHS Wrapper** | Bubblewrap/chroot environment allowing Gowin IDE (`gw_ide`) to run on NixOS. |

### 7. ThinkPad T480s Hardware Management

| Tool | Purpose |
|---|---|
| **TLP** | Advanced Linux power management optimized for single battery (`BAT0`) charge thresholds (20% start, 80% stop). |
| **Throttled** | Intel CPU voltage and thermal throttling controller (undervolts CPU core/cache to reduce heat). |
| **Thinkfan** | Custom fan-speed curve daemon monitoring temperature sensors via ACPI. |
| **Fprintd** | Synaptics `06cb:00bd` fingerprint reader service integrated into PAM for login, sudo, and polkit. |
| **ModemManager & libqmi** | Cellular modem daemon managing Sierra EM7455 and Fibocom L850-GL with automated FCC unlock. |
| **Brightnessctl** | Safe, permission-free backlight and keyboard backlight brightness control. |
| **TrackPoint Tuning** | Kernel sysfs rules adjusting sensitivity, speed, and inertia for the red TrackPoint cap. |
| **ZRAM** | Compressed in-memory swap using `zstd` (50% RAM), sparing NVMe SSD wear. |

### 8. GNOME Extensions & Desktop Themes

#### Desktop Themes & Visual Styling
| Component | Setting / Package | Description |
|---|---|---|
| **GTK Theme** | `adw-gtk3-dark` | Adapts legacy GTK3 applications to look identical to GNOME's modern Libadwaita dark style, providing a cohesive dark aesthetic across all apps. |
| **Icon Theme** | `Papirus-Dark` | Crisp, high-contrast SVG icon theme with dark panel tray icons and extensive application icon coverage. |
| **Cursor Theme** | `Bibata-Modern-Ice` (24px) | Clean, rounded white-and-black cursor theme. Unified across Wayland, XWayland, and GTK via `home.pointerCursor`. |
| **Monospace Font** | `JetBrainsMono Nerd Font Mono 11` | Fixed-pitch coding font with programming ligatures and developer icons; strictly fixed-width to avoid terminal column misalignment. |
| **UI Font** | `Inter 11` | Highly readable, modern sans-serif typography optimized for computer displays. |
| **Document Font** | `Source Serif Pro 11` | Elegant serif typeface used for document reading and PDF viewers. |

#### GNOME Extensions (Preconfigured via dconf)
| Extension | Role & Configuration |
|---|---|
| **Dash to Dock** | Moves the dash out of the overview into a permanent, auto-hiding dock pinned to the **left screen edge** with 36px icons, running app dots, and click-to-minimize. |
| **Blur my Shell** | Adds frosted-glass blur effects behind the top bar, dock, window overview, and lock screen. |
| **Pop Shell** | Keyboard-driven auto-tiling window manager (from Pop!_OS). Automatically tiles windows, sets 4px gaps, active window border hints, and shortcuts (`Super` + navigation). |
| **Just Perfection** | Declutters the shell: hides the redundant "Activities" text button, removes workspace switcher delays, and smooths animations. |
| **Vitals** | Real-time hardware telemetry in the top bar: CPU temperature & load, RAM usage, battery percentage, fan RPM, and network download/upload speeds. |
| **AppIndicator Support** | Restores the system tray in the top bar for background apps like Discord/Vesktop, Bitwarden, Steam, Telegram, and Syncthing. |
| **Caffeine** | One-click top bar toggle to prevent the screen from dimming, sleeping, or locking during long builds, tests, or presentations. |
| **Clipboard Indicator** | Top bar clipboard history manager with searchable entries, quick paste, and private mode. |
| **GSConnect** | Complete wireless Android phone integration (KDE Connect protocol): syncs notifications, SMS, battery status, clipboard, and two-way file sharing. |
| **Rounded Window Corners Reborn** | Enforces consistent, smooth rounded corners on all windows (including legacy GTK3 and Electron apps). |
| **Grand Theft Focus** | Eliminates the "Window is ready" notification popup and focuses newly launched applications immediately. |
| **Night Theme Switcher** | Automates transition between light and dark themes synchronized with local sunrise and sunset. |
| **User Themes** | Unlocks custom GNOME Shell stylesheet theming. |
| **Forge** | Lightweight tiling window manager and split-screen organizer for additional layout flexibility. |

---

## Hardware Management Reference

### 1. Fingerprint Enrollment
```bash
# Enroll a finger
fprintd-enroll

# Verify enrollment
fprintd-verify
```
*PAM accepts either your fingerprint or password for GDM login, `sudo`, polkit, and screen lock.*

### 2. SIM Card / Mobile Broadband (WWAN)
```bash
# Check modem status
mmcli -L
mmcli -m 0

# Connect mobile data (or connect via GNOME Settings → Network)
nmcli connection add type gsm ifname '*' con-name "LTE" apn "internet"
```

### 3. Battery Thresholds
```bash
# Check battery health and charging status
tlp-stat -b

# Check current charge thresholds (20% start, 80% stop)
cat /sys/class/power_supply/BAT0/charge_control_start_threshold
cat /sys/class/power_supply/BAT0/charge_control_end_threshold
```

### 4. WireGuard VPN Import (GNOME)
1. Open **GNOME Settings** &rarr; **Network**.
2. Click **`+`** next to **VPN**.
3. Select **"Import from file..."** and pick your `.conf` configuration file.
4. Toggle VPN on/off anytime from the top-right GNOME Quick Settings menu.

### 5. Vivado & Gowin EDA
- **Vivado**: Install to `/opt/Xilinx` &rarr; launch simply by running `vivado`.
- **Gowin EDA**: Extract to `/opt/gowin` &rarr; launch by running `gowin-eda`.

---

## Helpful Commands

```bash
# System rebuild
sudo nixos-rebuild switch --flake ~/nixos-config#sumatra

# Clean old generations & garbage collect
nix-collect-garbage -d
sudo /run/current-system/bin/switch-to-configuration boot

# Check active virtual machines
virsh list --all
```
