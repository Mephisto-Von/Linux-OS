#!/usr/bin/env bash
# Boot-test a built Samurai Linux ISO in QEMU.
set -euo pipefail

REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)
ISO="${1:-}"
MODE="${2:-headless}"
MEM="${QEMU_MEM:-4096}"
TIMEOUT="${QEMU_TIMEOUT:-180}"
LOG="${QEMU_LOG:-$REPO_ROOT/build/qemu-serial.log}"
SCREENSHOT="${QEMU_SCREENSHOT:-$REPO_ROOT/build/qemu-screen.ppm}"
SCREENSHOT_DELAY="${QEMU_SCREENSHOT_DELAY:-120}"
MONITOR_SOCKET="${QEMU_MONITOR_SOCKET:-$REPO_ROOT/build/qemu-monitor.sock}"
SHOT_PID=""

log() { printf '==> %s\n' "$*"; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

cleanup() {
    if [[ -n "$SHOT_PID" ]]; then
        kill "$SHOT_PID" 2>/dev/null || true
        wait "$SHOT_PID" 2>/dev/null || true
    fi
    rm -f "$MONITOR_SOCKET"
}
trap cleanup EXIT

usage() {
    cat <<'EOF'
Usage: bash build/qemu-test.sh <iso> [--gui]

Without --gui the VM runs headless, writes serial output to build/qemu-serial.log,
captures a VGA screenshot at QEMU_SCREENSHOT_DELAY seconds, and exits after
QEMU_TIMEOUT seconds (default 180).
EOF
}

[[ -n "$ISO" ]] || { usage; exit 1; }
[[ -f "$ISO" ]] || die "ISO not found: $ISO"
[[ "$MODE" == "--gui" || "$MODE" == "headless" ]] || die "Unknown mode: $MODE"
command -v qemu-system-x86_64 >/dev/null 2>&1 || die "qemu-system-x86_64 is not installed"

ACCEL=()
if [[ -w /dev/kvm ]]; then
    ACCEL=(-enable-kvm -cpu host)
else
    # The default qemu64 CPU lacks features some recent kernels/glibc builds use.
    ACCEL=(-cpu max)
fi

BASE=(qemu-system-x86_64 -name "Samurai Linux" -m "$MEM" -smp 2 -cdrom "$ISO" -boot d)
log "ISO: $ISO"
log "Serial log: $LOG"
log "VGA screenshot: $SCREENSHOT"

if [[ "$MODE" == "--gui" ]]; then
    "${BASE[@]}" "${ACCEL[@]}" -serial "file:$LOG"
    exit 0
fi

rm -f "$LOG" "$SCREENSHOT" "$MONITOR_SOCKET"

(
    sleep "$SCREENSHOT_DELAY"
    python3 - "$MONITOR_SOCKET" "$SCREENSHOT" <<'PY'
import socket
import sys
import time

sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
try:
    sock.connect(sys.argv[1])
    time.sleep(0.2)
    sock.sendall(f"screendump {sys.argv[2]}\n".encode())
    time.sleep(0.5)
finally:
    sock.close()
PY
) &
SHOT_PID=$!

status=0
timeout "$TIMEOUT" "${BASE[@]}" "${ACCEL[@]}" \
    -display none -serial "file:$LOG" \
    -monitor "unix:$MONITOR_SOCKET,server=on,wait=off" -no-reboot || status=$?
if ((status != 0 && status != 124)); then
    die "QEMU exited with status $status"
fi

if [[ ! -f "$LOG" ]]; then
    die "QEMU produced no serial log at $LOG"
fi

if grep -qiE 'Linux version|systemd\[1\]|Reached target|Startup finished|login:|sddm' "$LOG"; then
    log "Boot signs found in $LOG"
else
    printf '%s\n' '--- last serial lines ---' >&2
    tail -n 20 "$LOG" >&2 || true
    if [[ -f "$SCREENSHOT" ]]; then
        printf 'VGA screenshot saved to %s\n' "$SCREENSHOT" >&2
    else
        printf '%s\n' 'No VGA screenshot was captured.' >&2
    fi
    die "No boot signs found in $LOG"
fi
