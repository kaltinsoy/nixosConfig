# tlp-profile: switch ThinkPad T480s battery charge-threshold presets.
#
#   raw-ac   25% / 30%   AC pass-through, battery idles (default in lenovo.nix)
#   normal   75% / 80%   daily use, battery health preserved
#   full     96% / 100%  travel / long sessions away from power
#   status               show power source, level, thresholds
#
# Changes are temporary: TLP re-applies the lenovo.nix defaults on boot,
# resume and power-source events. Needs no root — lenovo.nix opens the
# threshold files to all users via udev.

BAT_DIR="/sys/class/power_supply/BAT0"
AC_DIR="/sys/class/power_supply/AC"

BOLD="\033[1m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RED="\033[1;31m"
RESET="\033[0m"

read_sysfs() {
    if [ -r "$1" ]; then cat "$1" 2>/dev/null || echo "N/A"; else echo "N/A"; fi
}

# Read a threshold from the modern name, falling back to the legacy one.
read_threshold() {
    local v
    v=$(read_sysfs "$BAT_DIR/charge_control_$1_threshold")
    [ "$v" = "N/A" ] && v=$(read_sysfs "$BAT_DIR/charge_$2_threshold")
    echo "$v"
}

write_sysfs() {
    if [ -w "$1" ]; then echo "$2" > "$1" 2>/dev/null || true; fi
}

set_thresholds() {
    local start="$1" stop="$2" cur_stop

    if ! [[ "$start" =~ ^[0-9]+$ ]] || ! [[ "$stop" =~ ^[0-9]+$ ]] || [ "$stop" -gt 100 ]; then
        echo -e "${RED}Error: thresholds must be integers between 0 and 100.${RESET}"
        exit 1
    fi
    if [ "$start" -ge "$stop" ]; then
        echo -e "${RED}Error: start ($start) must be lower than stop ($stop).${RESET}"
        exit 1
    fi

    # The kernel rejects start >= stop, so write whichever bound moves away
    # from the other one first (e.g. 25/30 -> 75/80 must raise stop first).
    cur_stop=$(read_threshold end stop)
    if [[ "$cur_stop" =~ ^[0-9]+$ ]] && [ "$stop" -gt "$cur_stop" ]; then
        write_sysfs "$BAT_DIR/charge_control_end_threshold" "$stop"
        write_sysfs "$BAT_DIR/charge_stop_threshold" "$stop"
        write_sysfs "$BAT_DIR/charge_control_start_threshold" "$start"
        write_sysfs "$BAT_DIR/charge_start_threshold" "$start"
    else
        write_sysfs "$BAT_DIR/charge_control_start_threshold" "$start"
        write_sysfs "$BAT_DIR/charge_start_threshold" "$start"
        write_sysfs "$BAT_DIR/charge_control_end_threshold" "$stop"
        write_sysfs "$BAT_DIR/charge_stop_threshold" "$stop"
    fi

    if [ "$(read_threshold start start)" != "$start" ] || [ "$(read_threshold end stop)" != "$stop" ]; then
        echo -e "${RED}Error: could not set thresholds to $start/$stop (sysfs not writable?).${RESET}"
        echo "Try: sudo tlp setcharge $start $stop BAT0"
        exit 1
    fi
}

# Drop any manual tlpctl override so TLP follows the power source again.
reset_power_profile() {
    tlpctl balanced >/dev/null 2>&1 || true
}

show_status() {
    local capacity status start_th stop_th ac_online governor epp profile

    capacity=$(read_sysfs "$BAT_DIR/capacity")
    status=$(read_sysfs "$BAT_DIR/status")
    start_th=$(read_threshold start start)
    stop_th=$(read_threshold end stop)
    ac_online=$(read_sysfs "$AC_DIR/online")
    governor=$(read_sysfs "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor")
    epp=$(read_sysfs "/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference")
    profile=$(tlpctl get 2>/dev/null || echo "N/A")

    echo -e "${BOLD}=== ThinkPad Power & Battery Profile Status ===${RESET}"
    if [ "$ac_online" = "1" ]; then
        echo -e "• Power Source:     ${GREEN}AC Adapter (Plugged in)${RESET}"
    else
        echo -e "• Power Source:     ${YELLOW}Battery (AC Disconnected)${RESET}"
    fi

    echo -e "• Battery Level:    ${BOLD}${capacity}%${RESET}"
    case "$status" in
        "Charging")    echo -e "• Battery Status:   ${GREEN}Charging${RESET}" ;;
        "Not charging") echo -e "• Battery Status:   ${CYAN}Not charging (bypassed / idle)${RESET}" ;;
        "Discharging") echo -e "• Battery Status:   ${YELLOW}Discharging${RESET}" ;;
        *)             echo -e "• Battery Status:   $status" ;;
    esac

    echo -e "• Thresholds:       Start at ${BOLD}${start_th}%${RESET}, Stop at ${BOLD}${stop_th}%${RESET}"

    if [ "$stop_th" -le 35 ] && [ "$stop_th" -gt 0 ] 2>/dev/null; then
        echo -e "• Charge Profile:   ${GREEN}RAW-AC / BYPASS${RESET} (AC pass-through, battery idle)"
    elif [ "$stop_th" -ge 70 ] && [ "$stop_th" -le 85 ] 2>/dev/null; then
        echo -e "• Charge Profile:   ${CYAN}NORMAL LONGEVITY${RESET} (75-80%)"
    elif [ "$stop_th" -ge 95 ] 2>/dev/null; then
        echo -e "• Charge Profile:   ${YELLOW}FULL CHARGE${RESET} (travel, 100%)"
    else
        echo -e "• Charge Profile:   Custom (${start_th}% - ${stop_th}%)"
    fi

    echo -e "• TLP Profile:      ${BOLD}${profile}${RESET}"
    echo -e "• CPU Governor:     ${BOLD}${governor}${RESET} (EPP: ${epp})"
}

apply_raw_ac() {
    local capacity ac_online
    capacity=$(read_sysfs "$BAT_DIR/capacity")
    ac_online=$(read_sysfs "$AC_DIR/online")

    echo -e "${BOLD}[Setting Profile: Raw AC Bypass]${RESET}"
    set_thresholds 25 30
    reset_power_profile
    echo -e "${GREEN}✓ Thresholds set: start 25% | stop 30%${RESET}"

    if [ "$capacity" -ge 30 ] 2>/dev/null; then
        echo -e "${CYAN}→ Battery is at ${capacity}%: on AC it will neither charge nor discharge.${RESET}"
    else
        echo -e "${YELLOW}→ Battery is at ${capacity}%: on AC it charges to 30%, then switches to bypass.${RESET}"
    fi
    if [ "$ac_online" != "1" ]; then
        echo -e "${YELLOW}[!] AC adapter is unplugged. Connect AC to use pass-through power.${RESET}"
    fi
}

apply_normal() {
    echo -e "${BOLD}[Setting Profile: Normal Battery Longevity]${RESET}"
    set_thresholds 75 80
    reset_power_profile
    echo -e "${GREEN}✓ Thresholds set: start 75% | stop 80%${RESET}"
}

apply_full() {
    echo -e "${BOLD}[Setting Profile: Full Charge]${RESET}"
    set_thresholds 96 100
    reset_power_profile
    echo -e "${GREEN}✓ Thresholds set: start 96% | stop 100%${RESET}"
    echo "  Battery will charge to full capacity (useful for travel)."
}

print_help() {
    echo -e "${BOLD}Usage:${RESET} tlp-profile [COMMAND]  (or: ac-bypass [on|off])"
    echo ""
    echo "Commands:"
    echo "  raw-ac, bypass, on   AC pass-through, battery idles at 25-30%"
    echo "  normal, off          Longevity thresholds (75% - 80%)"
    echo "  full, 100            Charge to 100% (for travel)"
    echo "  status               Show battery, AC, thresholds and CPU mode"
    echo "  help, -h, --help     Show this help message"
}

CMD="${1:-status}"

case "$CMD" in
    raw-ac|raw|bypass|on)            apply_raw_ac ;;
    normal|default|longevity|off)    apply_normal ;;
    full|100)                        apply_full ;;
    status)                          show_status ;;
    help|-h|--help)                  print_help ;;
    *)
        echo -e "${RED}Unknown command: $CMD${RESET}\n"
        print_help
        exit 1
        ;;
esac
