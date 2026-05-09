#!/usr/bin/env bash
set -euo pipefail

# Portuus Server Stability Test Suite
# Run after memtest86+ passes. Logs to /var/log/stress-test-results/
# Usage: nix-shell -p stress-ng lm_sensors smartmontools --run "sudo bash stress-test.sh"
# Duration: ~80 minutes (5 tests with cooldown pauses)

LOG_DIR="/var/log/stress-test-results"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG="$LOG_DIR/stress-$TIMESTAMP.log"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }

# System info
log "=== SYSTEM INFO ==="
log "Hostname: $(hostname)"
log "Kernel: $(uname -r)"
log "CPU: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
log "Cores: $(nproc)"
log "RAM: $(free -h | awk '/Mem:/ {print $2}')"
log "Uptime: $(uptime)"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT >> "$LOG" 2>&1

# Baseline temps and voltages
log ""
log "=== BASELINE SENSORS ==="
sensors >> "$LOG" 2>&1 || log "sensors not available"

# Check for previous crash indicators
log ""
log "=== PREVIOUS CRASH INDICATORS ==="
log "--- MCE (Machine Check Exceptions) ---"
dmesg | grep -iE "mce|machine check" >> "$LOG" 2>&1 || log "no MCE found"
log "--- OOM Killer ---"
dmesg | grep -iE "oom|killed process|out of memory" >> "$LOG" 2>&1 || log "no OOM found"
log "--- Hardware errors ---"
dmesg | grep -iE "hardware error|nmi|pcie.*error|aer.*error|uncorrectable" >> "$LOG" 2>&1 || log "no HW errors found"
log "--- Previous boot crash ---"
journalctl -b -1 -p err --no-pager 2>> "$LOG" | tail -30 >> "$LOG" 2>&1 || log "no previous boot journal"

# SMART disk health
log ""
log "=== DISK HEALTH ==="
for disk in /dev/sd? /dev/nvme?n?; do
    [ -e "$disk" ] && smartctl -H "$disk" >> "$LOG" 2>&1 || true
done

# ZFS status
log ""
log "=== ZFS STATUS ==="
zpool status >> "$LOG" 2>&1 || log "no ZFS pools"
zpool list >> "$LOG" 2>&1 || true

# Monitor temps during stress (background)
monitor_temps() {
    while true; do
        echo "[$(date '+%H:%M:%S')] $(sensors 2>/dev/null | grep -E 'Core|temp|fan' | tr '\n' ' ')" >> "$LOG_DIR/temps-$TIMESTAMP.log"
        sleep 10
    done
}
monitor_temps &
MONITOR_PID=$!
trap "kill $MONITOR_PID 2>/dev/null; wait $MONITOR_PID 2>/dev/null" EXIT

# Test 1: CPU only
log ""
log "=== TEST 1: CPU STRESS (15 min) ==="
log "Start: $(date)"
stress-ng --cpu $(nproc) --cpu-method all --timeout 900 --metrics 2>&1 | tee -a "$LOG"
log "End: $(date)"
log "Temps after CPU test:"
sensors >> "$LOG" 2>&1 || true

sleep 30

# Test 2: RAM only
log ""
log "=== TEST 2: RAM STRESS (15 min) ==="
log "Start: $(date)"
stress-ng --vm 4 --vm-bytes 75% --vm-method all --timeout 900 --metrics 2>&1 | tee -a "$LOG"
log "End: $(date)"
log "Temps after RAM test:"
sensors >> "$LOG" 2>&1 || true

sleep 30

# Test 3: CPU + RAM combined
log ""
log "=== TEST 3: CPU + RAM COMBINED (15 min) ==="
log "Start: $(date)"
stress-ng --cpu $(nproc) --vm 2 --vm-bytes 50% --timeout 900 --metrics 2>&1 | tee -a "$LOG"
log "End: $(date)"
log "Temps after combined test:"
sensors >> "$LOG" 2>&1 || true

sleep 30

# Test 4: IO stress
log ""
log "=== TEST 4: DISK IO STRESS (10 min) ==="
log "Start: $(date)"
stress-ng --iomix 4 --timeout 600 --metrics 2>&1 | tee -a "$LOG"
log "End: $(date)"

sleep 30

# Test 5: Full system stress (everything at once)
log ""
log "=== TEST 5: FULL SYSTEM STRESS (20 min) ==="
log "Start: $(date)"
stress-ng --cpu $(nproc) --vm 2 --vm-bytes 50% --iomix 2 --timeout 1200 --metrics 2>&1 | tee -a "$LOG"
log "End: $(date)"

# Final state
log ""
log "=== FINAL STATE ==="
log "Uptime: $(uptime)"
sensors >> "$LOG" 2>&1 || true
free -h >> "$LOG" 2>&1
zpool status >> "$LOG" 2>&1 || true

log ""
log "=== ALL TESTS COMPLETED ==="
log "Results saved to $LOG"
log "Temperature log: $LOG_DIR/temps-$TIMESTAMP.log"
log "If the server froze during a test, the last entry in the log shows which test caused it."
