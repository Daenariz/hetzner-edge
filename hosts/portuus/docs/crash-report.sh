#!/usr/bin/env bash
set -euo pipefail

# Portuus Crash Report — collects evidence from previous freezes/crashes.
# Usage: nix-shell -p smartmontools --run "sudo bash crash-report.sh"
# Results saved to /var/log/crash-reports/

LOG_DIR="/var/log/crash-reports"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG="$LOG_DIR/crash-report-$TIMESTAMP.log"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }

log "=== CRASH REPORT $(date) ==="
log "Uptime since last boot: $(uptime -s)"

# List all boots
log ""
log "=== BOOT HISTORY (last 20) ==="
journalctl --list-boots 2>/dev/null | tail -20 >> "$LOG" 2>&1

# Check each previous boot for errors
BOOTS=$(journalctl --list-boots 2>/dev/null | awk '{print $1}' | head -10)
for BOOT in $BOOTS; do
    log ""
    log "=== BOOT $BOOT ==="

    log "--- Critical/Emergency messages ---"
    journalctl -b "$BOOT" -p crit --no-pager 2>/dev/null | tail -20 >> "$LOG" 2>&1 || true

    log "--- MCE (Machine Check Exceptions) ---"
    journalctl -b "$BOOT" --no-pager 2>/dev/null | grep -iE "mce|machine.check" | tail -10 >> "$LOG" 2>&1 || true

    log "--- Hardware errors ---"
    journalctl -b "$BOOT" --no-pager 2>/dev/null | grep -iE "hardware.error|nmi|pcie.*error|aer|uncorrectable|fatal" | tail -10 >> "$LOG" 2>&1 || true

    log "--- OOM Killer ---"
    journalctl -b "$BOOT" --no-pager 2>/dev/null | grep -iE "oom|killed.process|out.of.memory" | tail -10 >> "$LOG" 2>&1 || true

    log "--- GPU/DRM errors ---"
    journalctl -b "$BOOT" --no-pager 2>/dev/null | grep -iE "gpu|drm|amdgpu|nvidia|hang|wedged" | tail -10 >> "$LOG" 2>&1 || true

    log "--- USB/PCIe errors ---"
    journalctl -b "$BOOT" --no-pager 2>/dev/null | grep -iE "usb.*error|pci.*error|link.down|aer.*correctable" | tail -10 >> "$LOG" 2>&1 || true

    log "--- Kernel panics/oops ---"
    journalctl -b "$BOOT" --no-pager 2>/dev/null | grep -iE "kernel.*panic|oops|bug:|rcu.*stall|soft.lockup|hard.lockup|watchdog" | tail -10 >> "$LOG" 2>&1 || true

    log "--- ZFS errors ---"
    journalctl -b "$BOOT" --no-pager 2>/dev/null | grep -iE "zfs.*error|zfs.*fault|zpool|checksum|i/o.error" | tail -10 >> "$LOG" 2>&1 || true

    log "--- Disk I/O errors ---"
    journalctl -b "$BOOT" --no-pager 2>/dev/null | grep -iE "blk_update|i/o error|medium error|sector|ata.*error|sata.*error" | tail -10 >> "$LOG" 2>&1 || true

    log "--- Freezes / hung tasks ---"
    journalctl -b "$BOOT" --no-pager 2>/dev/null | grep -iE "hung_task|blocked for more than|not tainted|task.*blocked" | tail -10 >> "$LOG" 2>&1 || true

    log "--- Last 20 messages before shutdown/crash ---"
    journalctl -b "$BOOT" --no-pager 2>/dev/null | tail -20 >> "$LOG" 2>&1 || true
done

# Current kernel ring buffer
log ""
log "=== CURRENT DMESG ERRORS ==="
dmesg --level=err,crit,alert,emerg 2>/dev/null | tail -30 >> "$LOG" 2>&1 || true

# EDAC (ECC memory errors if supported)
log ""
log "=== EDAC (Memory Error Detection) ==="
find /sys/devices/system/edac -name "ce_count" -o -name "ue_count" 2>/dev/null | while read -r f; do
    echo "$f: $(cat "$f")" >> "$LOG"
done || log "no EDAC support"

# SMART disk health
log ""
log "=== DISK SMART ERRORS ==="
for disk in /dev/sd? /dev/nvme?n?; do
    if [ -e "$disk" ]; then
        log "--- $disk ---"
        smartctl -H "$disk" >> "$LOG" 2>&1 || true
        smartctl -l error "$disk" >> "$LOG" 2>&1 || true
    fi
done

# ZFS pool status
log ""
log "=== ZFS POOL STATUS ==="
zpool status -v >> "$LOG" 2>&1 || true
zpool events -v 2>/dev/null | tail -30 >> "$LOG" 2>&1 || true

# Power supply / ACPI events
log ""
log "=== POWER / ACPI EVENTS ==="
journalctl --no-pager 2>/dev/null | grep -iE "acpi.*error|power.*fail|voltage|thermal.*trip|critical.*temp" | tail -20 >> "$LOG" 2>&1 || log "none found"

# Memory pressure
log ""
log "=== CURRENT MEMORY STATE ==="
free -h >> "$LOG" 2>&1
cat /proc/meminfo | grep -E "MemTotal|MemAvail|SwapTotal|SwapFree|AnonPages|Slab|ArcSize" >> "$LOG" 2>&1 || true

# ZFS ARC memory usage (ZFS can consume all available RAM)
log ""
log "=== ZFS ARC MEMORY ==="
cat /proc/spl/kstat/zfs/arcstats 2>/dev/null | grep -E "^size|^c_max|^c_min" >> "$LOG" 2>&1 || log "no ARC stats"

# Uptime pattern — short uptimes indicate frequent crashes
log ""
log "=== BOOT TIMESTAMPS (crash frequency) ==="
journalctl --list-boots 2>/dev/null | awk '{print $3, $4}' | tail -20 >> "$LOG" 2>&1

# TPM lockout state
log ""
log "=== TPM STATE ==="
cat /sys/class/tpm/tpm0/tpm_version_major >> "$LOG" 2>&1 || log "no TPM"

# Interrupted services (services that didn't shut down cleanly)
log ""
log "=== FAILED SERVICES (current boot) ==="
systemctl --failed --no-pager >> "$LOG" 2>&1 || true

# Hardware info for context
log ""
log "=== HARDWARE INFO ==="
lscpu | grep -E "Model name|Socket|Core|Thread|CPU MHz" >> "$LOG" 2>&1 || true
cat /proc/meminfo | head -5 >> "$LOG" 2>&1
lspci 2>/dev/null | grep -iE "vga|3d|display|audio|sata|nvme|usb.*host" >> "$LOG" 2>&1 || true

log ""
log "=== REPORT COMPLETE ==="
log "Saved to: $LOG"
