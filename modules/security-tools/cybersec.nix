{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # ── Network scanning & analysis ────────────────────────────────────
    nmap
    masscan
    rustscan             # fast port scanner
    arp-scan
    netcat-gnu
    socat
    tcpdump
    wireshark            # GUI
    tshark               # CLI wireshark
    termshark            # TUI wireshark
    tcpflow
    mitmproxy            # HTTPS MITM proxy
    ettercap             # network sniffer / MITM
    bettercap            # network attack framework

    # ── Web application testing ────────────────────────────────────────
    burpsuite
    sqlmap
    gobuster
    ffuf
    nikto
    wfuzz
    httpie
    curl
    feroxbuster

    # ── Password / credential ──────────────────────────────────────────
    john                 # John the Ripper
    hashcat
    hydra                # online password brute-force
    medusa
    crunch               # wordlist generator
    wordlists            # rockyou, etc.

    # ── Exploitation framework ────────────────────────────────────────
    metasploit
    # exploitdb          # large DB; enable if needed

    # ── Reverse engineering / binary analysis ─────────────────────────
    ghidra               # NSA RE framework
    radare2              # RE framework
    iaito                # Ghidra/radare2 GUI
    gdb
    #pwndbg               # GDB plug-in for exploit dev
    pwntools             # Python exploit dev lib
    binwalk              # firmware analysis
    file
    hexyl                # hex viewer
    xxd
    imhex                # hex editor
    checksec             # binary hardening checker
    yara                 # malware pattern matching

    # ── Wireless ──────────────────────────────────────────────────────
    aircrack-ng
    hostapd
    iw
    wavemon
    hcxtools             # WPA capture conversion
    hcxdumptool

    # ── OSINT ─────────────────────────────────────────────────────────
    maltego              # OSINT / threat intel
    theharvester
    amass                # subdomain enumeration

    # ── Forensics ─────────────────────────────────────────────────────
    volatility3          # memory forensics
    foremost             # file carving
    autopsy              # GUI forensics platform
    bulk_extractor
    sleuthkit

    # ── Crypto / stego ────────────────────────────────────────────────
    steghide
    stegseek
    openssl
    age                  # modern encryption

    # ── Containers in cybersec labs ───────────────────────────────────
    docker-compose
    lazydocker

    # ── Misc tooling ──────────────────────────────────────────────────
    proxychains-ng       # force TCP through proxy
    tor
    torsocks
    onionshare-gui
    openvpn
    wireguard-tools
  ];

  # ── Wireshark group for packet capture without root ───────────────────
  programs.wireshark = {
    enable  = true;
    package = pkgs.wireshark;
  };

  # ── Tor service (optional — uncomment to run a local SOCKS proxy) ─────
  # services.tor = {
  #   enable = true;
  #   client.enable = true;
  # };

  # ── Kernel settings useful for security research ──────────────────────
  boot.kernel.sysctl = {
    # Allow raw socket operations (for custom packet crafting)
    "net.ipv4.ping_group_range" = "0 65535";
    # Enable IP forwarding for routing/MITM labs
    "net.ipv4.ip_forward"       = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
}
