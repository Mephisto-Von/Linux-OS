#!/usr/bin/env bash
# Post-build workflow: REA ISO analysis plus optional Heretic model processing.
set -euo pipefail

REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)
ISOS=()
MODEL=""

usage() {
    cat <<'EOF'
Usage: ./scripts/post-build-workflow.sh [iso ...] [--heretic <model-id>]

With no ISO arguments, every ref/*.iso is analyzed. Heretic processing is
skipped unless --heretic <model-id> is supplied, so the script is non-interactive
and safe to run in CI.
EOF
}

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }
log() { printf '==> %s\n' "$*"; }

while (($# > 0)); do
    case "$1" in
        --heretic)
            (($# >= 2)) || die "--heretic requires a model id"
            MODEL="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            die "Unknown option: $1"
            ;;
        *)
            ISOS+=("$1")
            shift
            ;;
    esac
done

if ((${#ISOS[@]} == 0)); then
    shopt -s nullglob
    ISOS=( "$REPO_ROOT"/ref/*.iso )
    shopt -u nullglob
fi

if ((${#ISOS[@]} == 0)); then
    log "No ISO files found (pass paths or put images in ref/); skipping REA analysis"
else
    for iso in "${ISOS[@]}"; do
        [[ -f "$iso" ]] || die "ISO not found: $iso"
        log "Analyzing $iso"
        bash "$REPO_ROOT/scripts/analyze-iso.sh" "$iso"
    done
fi

if [[ -n "$MODEL" ]]; then
    log "Running Heretic for $MODEL"
    python3 "$REPO_ROOT/scripts/use-heretic.py" "$MODEL"
else
    log "Skipping Heretic (pass --heretic <model-id> to enable)"
fi

log "Workflow complete"
