# NixOS Config — Cybersec / FPGA / Desktop

Modular NixOS flake for a Lenovo ThinkPad running GNOME on Wayland.
Covers cybersecurity research, FPGA development (Xilinx Vivado + Gowin + OSS chain),
QEMU/KVM virtualization, and a polished desktop experience.

## Quick Start

```bash
# 1. Clone to your home dir
git clone <this-repo> ~/nixos-config

# 2. Generate real hardware config and replace the placeholder
sudo nixos-generate-config --show-hardware-config \
  > ~/nixos-config/hosts/default/hardware-configuration.nix

# 3. Edit the two variables at the top of flake.nix
#    username = "koray"   ← already set
#    hostname = "nixos"   ← change if needed

# 4. Edit your email in home/home.nix (git.userEmail)

# 5. Apply
sudo nixos-rebuild switch --flake ~/nixos-config#nixos

# 6. Home Manager (first time or user-only changes)
home-manager switch --flake ~/nixos-config#nixos
```

## File Tree

```
nixos-config/
├── flake.nix
├── hosts/default/
│   ├── configuration.nix        # Top-level imports
│   └── hardware-configuration.nix  # REPLACE with nixos-generate-config output
└── modules/
    ├── system/    boot · networking · locale · security · services
    ├── desktop/   gnome · fonts
    ├── hardware/  lenovo  (TLP · throttled · thinkfan · fwupd)
    ├── virt/      qemu-kvm  (libvirtd · docker · virt-manager)
    ├── fpga/      fpga  (yosys · nextpnr · Vivado FHS · Gowin FHS · openFPGALoader)
    └── security-tools/  cybersec  (nmap · ghidra · metasploit · wireshark · …)
home/
├── home.nix
├── neovim/   NvChad + LSP + formatters
├── shell/    starship + aliases
├── apps/     zen-browser · spicetify-spotify · firefox
└── gnome-extensions/  dconf settings for all extensions
```

## Notable Features

| Area | Tools |
|---|---|
| **Desktop** | GNOME + Wayland, Dash-to-Dock, Blur-my-Shell, Pop-Shell tiling, Vitals |
| **Editor** | NvChad (Neovim) with LSP for Nix, C/C++, Python, Rust, Verilog, TS |
| **Browser** | Zen Browser + Firefox (hardened) + Tor Browser |
| **Music** | Spicetify (Catppuccin Mocha theme, ad-block, lyrics, full-screen) |
| **Cybersec** | nmap · masscan · Wireshark · Burp Suite · Ghidra · Metasploit · Hashcat · Volatility |
| **Virt** | QEMU/KVM · libvirtd · virt-manager · Docker · OVMF/UEFI · SPICE · Looking Glass |
| **FPGA OSS** | Yosys · nextpnr · Icestorm · Trellis · GHDL · Verilator · GTKWave · SymbiYosys |
| **FPGA Prop.** | Vivado FHS wrapper (`/opt/Xilinx`) · Gowin EDA FHS wrapper (`/opt/gowin`) |
| **T480s HW** | TLP (single BAT0) · throttled · thinkfan · fwupd · acpi_call · zram |
| **Fingerprint** | fprintd (Synaptics 06cb:00bd) — PAM: sudo / GDM / polkit / lock screen |
| **SIM / WWAN** | ModemManager + libqmi/libmbim — Sierra EM7455 & Fibocom L850-GL FCC unlock |
| **Backlight** | `light` — no sudo, `video` group, TrackPoint sensitivity tuned via tmpfiles |
| **Shell** | Bash + Starship + fzf + zoxide + direnv |

---

## T480s Hardware Setup

### Fingerprint reader
```bash
# First enroll (do this after nixos-rebuild switch)
fprintd-enroll        # or alias: fp-enroll
# Enroll each finger you want, then test:
fp-verify
```
PAM is pre-configured to accept fingerprint **or** password at:
- GDM login
- `sudo` prompts
- Screen lock
- `pkexec` / polkit dialogs

### SIM card / WWAN (LTE)
```bash
# Check if modem is detected
mmcli -L
# Modem details + signal
wwan-status           # alias for: mmcli -m 0
# SIM card info (IMSI, ICCID)
sim-info
# Enable mobile data via NetworkManager (or GNOME Settings → Network)
nmcli connection add type gsm ifname '*' con-name "LTE" apn "internet"
```

> **FCC Unlock**: Some Sierra EM7455 units are carrier-locked at firmware level.
> The `fccUnlockScripts` in `lenovo.nix` handles this automatically on boot.

### Battery
```bash
bat-status   # show BAT0 status and charge thresholds
bat0-thresh  # show current start/stop thresholds
# Thresholds are set in lenovo.nix (START=20, STOP=80 by default)
```

### IR Camera
The T480s IR camera (`04f2:b615`) appears as a standard V4L2 device but does **not** support Windows Hello–style face unlock on Linux. Use the fingerprint reader instead.


## Proprietary Tools Setup

### Vivado
1. Download installer from xilinx.com
2. Run: `sudo ./Xilinx_Unified_<ver>_Linux_x64.bin`
3. Install to `/opt/Xilinx` (the FHS wrapper expects this)
4. Run with: `vivado` (uses the FHS wrapper in PATH)

### Gowin EDA
1. Download from gowin-semi.com (requires registration)
2. Extract to `/opt/gowin`
3. Run with: `gowin-eda`

### Lenovo CPU note
- **Intel** (default): `throttled` undervolting is enabled. Adjust `[UNDERVOLT]` values in `lenovo.nix`
- **AMD**: Comment out `services.throttled` and add `ryzenadj` instead

### ThinkPad model preset
Uncomment the matching line in `flake.nix`:
```nix
nixos-hardware.nixosModules.lenovo-thinkpad-x1-carbon-gen12
```

## Useful Aliases

```bash
nixos-rebuild-switch   # rebuild + switch
nix-clean              # garbage collect
vms                    # virsh list --all
vivado                 # launch Vivado via FHS
gowin                  # launch Gowin EDA via FHS
```

#ERROR
[nix-shell:~/nixos-config]$ sudo nixos-rebuild switch --flake ~/nixos-config#sumatra
evaluating derivation 'git+file:///home/koray/nixos-config#nixosConfigurations."
building the system configuration...
evaluation warning: 'system' has been renamed to/replaced by 'stdenv.hostPlatform.system'
evaluation warning: nixfmt-rfc-style is now the same as pkgs.nixfmt which should be used instead.
evaluation warning: LibreOffice upstream has changed the versioning, please use `libreoffice-stable` or just `libreoffice`
evaluation warning: koray profile: `programs.ssh` default values will be removed in the future.
                    Consider setting `programs.ssh.enableDefaultConfig` to false,
                    and manually set the default values you want to keep at
                    `programs.ssh.settings."*"`.
evaluation warning: koray profile: The default value of `programs.firefox.configPath` has changed from `".mozilla/firefox"` to `"${config.xdg.configHome}/mozilla/firefox"`.
                    You are currently using the legacy default (`".mozilla/firefox"`) because `home.stateVersion` is less than "26.05".
                    To silence this warning and keep legacy behavior, set:
                      programs.firefox.configPath = ".mozilla/firefox";
                    To adopt the new default behavior, set:
                      programs.firefox.configPath = "${config.xdg.configHome}/mozilla/firefox";

                    To migrate to the XDG path, move `~/.mozilla/firefox` to
                    `$XDG_CONFIG_HOME/mozilla/firefox` and remove the old directory.
                    Native messaging hosts are not moved by this option change.
error:
       … while calling the 'head' builtin
         at «github:NixOS/nixpkgs/20b1ddd1aa5ace70c9468305030aa4f9ef79671b?narHash=sha256-B44WL6h0XoLjJ41bUPJk0X5SDinLCII//6EcBLXKiJ0%3D»/lib/attrsets.nix:1729:13:
         1728|           if length values == 1 || pred here (elemAt values 1) (head values) then
         1729|             head values
             |             ^
         1730|           else

       … while evaluating the attribute 'value'
         at «github:NixOS/nixpkgs/20b1ddd1aa5ace70c9468305030aa4f9ef79671b?narHash=sha256-B44WL6h0XoLjJ41bUPJk0X5SDinLCII//6EcBLXKiJ0%3D»/lib/modules.nix:1181:7:
         1180|     // {
         1181|       value = addErrorContext "while evaluating the option `${showOption loc}':" (
             |       ^
         1182|         # Apply the 'apply' function to the merged value. This allows options to

       … while evaluating the option `system.build.toplevel':

       … while evaluating definitions from `/nix/store/hqplg5bh73ijq5g6xpwsxsgvz4fj6v2r-source/nixos/modules/system/activation/top-level.nix':

       … while evaluating the option `system.systemBuilderArgs':

       … while evaluating definitions from `/nix/store/hqplg5bh73ijq5g6xpwsxsgvz4fj6v2r-source/nixos/modules/system/activation/top-level.nix':

       … while evaluating the option `environment.sessionVariables':

       … while evaluating definitions from `/nix/store/hqplg5bh73ijq5g6xpwsxsgvz4fj6v2r-source/nixos/modules/services/desktop-managers/gnome.nix':

       … while evaluating the option `environment.systemPackages':

       … while evaluating definitions from `/nix/store/fvzcdvw37ghdds6rs1k25wdzgw58d3gm-source/modules/security-tools/cybersec.nix':

       (stack trace truncated; use '--show-trace' to show the full, detailed trace)

       error: undefined variable 'pwndbg'
       at /home/koray/nixos-config/modules/security-tools/cybersec.nix:49:5:
           48|     gdb
           49|     pwndbg               # GDB plug-in for exploit dev
             |     ^
           50|     pwntools             # Python exploit dev lib
Command 'nix --extra-experimental-features 'nix-command flakes' build --print-out-paths '/home/koray/nixos-config#nixosConfigurations."sumatra".config.system.build.toplevel' --no-link' returned non-zero exit status 1.

[nix-shell:~/nixos-config]$ 
