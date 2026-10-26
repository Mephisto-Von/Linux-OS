#!/usr/bin/env bash
# Boot-test a built Samurai Linux ISO in QEMU.
set -euo pipefail

REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)
ISO="${1:-}"
MODE="${2:-headless}"
MEM="${QEMU_MEM:-4096}"
TIMEOUT="${QEMU_TIMEOUT:-180}"
LOG="${QEMU_LOG:-$REPO_ROOT/build/qemu-serial.log}"

log() { printf '==> %s\n' "$*"; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<'EOF'
Usage: bash build/qemu-test.sh <iso> [--gui]

Without --gui the VM runs headless, writes serial output to build/qemu-serial.log,
and exits after QEMU_TIMEOUT seconds (default 180).
EOF
}

[[ -n "$ISO" ]] || { usage; exit 1; }
[[ -f "$ISO" ]] || die "ISO not found: $ISO"
[[ "$MODE" == "--gui" || "$MODE" == "headless" ]] || die "Unknown mode: $MODE"
command -v qemu-system-x86_64 >/dev/null 2>&1 || die "qemu-system-x86_64 is not installed"

ACCEL=()
if [[ -w /dev/kvm ]]; then
    ACCEL=(-enable-kvm -cpu host)
fi

BASE=(qemu-system-x86_64 -name "Samurai Linux" -m "$MEM" -smp 2 -cdrom "$ISO" -boot d)
log "ISO: $ISO"
log "Serial log: $LOG"

if [[ "$MODE" == "--gui" ]]; then
    "${BASE[@]}" "${ACCEL[@]}" -serial "file:$LOG"
    exit 0
fi

status=0
timeout "$TIMEOUT" "${BASE[@]}" "${ACCEL[@]}" -display none -serial "file:$LOG" -no-reboot || status=$?
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
    die "No boot signs found in $LOG"
fi
