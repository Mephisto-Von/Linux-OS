#!/usr/bin/env bash
# Build the Samurai Linux live ISO with Debian live-build.
set -euo pipefail

BUILD_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
REPO_ROOT=$(cd -- "$BUILD_DIR/.." && pwd)
MIN_DISK_GB="${SAMURAI_MIN_DISK_GB:-50}"
MIN_RAM_GB="${SAMURAI_MIN_RAM_GB:-4}"

log() { printf '==> %s\n' "$*"; }
warn() { printf 'Warning: %s\n' "$*" >&2; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<'EOF'
Build the Samurai Linux live ISO.

Usage: [sudo] bash build/build.sh [option]

Options:
  (none)       Clean, configure, build, and collect the ISO
  --check      Validate the host, sync assets, and generate the config only
  --clean      Remove live-build state and generated files
  --no-clean   Build without running `lb clean`
  -h, --help   Show this help

Environment:
  SAMURAI_MIN_DISK_GB   Required free disk in GiB (default: 50)
  SAMURAI_MIN_RAM_GB    Warn below this RAM in GiB (default: 4)
  SAMURAI_SIGN_KEY      GPG key id used to sign the ISO (optional)

Output:
  dist/samurai-linux-YYYY.MM.DD-amd64.iso
  dist/samurai-linux-YYYY.MM.DD-amd64.iso.sha256
  dist/samurai-linux-YYYY.MM.DD-amd64.iso.sig  (when SAMURAI_SIGN_KEY is set)
EOF
}

require_root() {
    ((EUID == 0)) || die "live-build must run as root. Use: sudo bash build/build.sh"
}

check_host() {
    [[ "$(uname -s)" == "Linux" ]] || die "A Linux build host is required"
    [[ "$(uname -m)" == "x86_64" ]] || die "Only x86_64 is supported"

    local tool
    for tool in lb debootstrap xorriso mksquashfs; do
        command -v "$tool" >/dev/null 2>&1 || die "Missing build tool: $tool (install live-build, debootstrap, xorriso, squashfs-tools)"
    done

    local available_kb available_gb
    available_kb=$(df -Pk "$REPO_ROOT" | awk 'NR == 2 { print $4 }')
    available_gb=$((available_kb / 1024 / 1024))
    if ((available_gb < MIN_DISK_GB)); then
        die "Need at least ${MIN_DISK_GB} GiB free, found ${available_gb} GiB on the build filesystem"
    fi

    local mem_kb mem_gb
    mem_kb=$(awk '/^MemTotal:/ { print $2 }' /proc/meminfo)
    mem_gb=$((mem_kb / 1024 / 1024))
    if ((mem_gb < MIN_RAM_GB)); then
        warn "Only ${mem_gb} GiB RAM detected; ${MIN_RAM_GB} GiB or more is recommended"
    fi

    log "Host check passed (${available_gb} GiB free, ${mem_gb} GiB RAM)"
}

sync_assets() {
    local includes="$BUILD_DIR/config/includes.chroot"
    local bin="$includes/usr/local/bin"
    local themes="$includes/usr/share/samurai/themes"

    rm -rf "$bin" "$themes"
    install -d -m 0755 "$bin" "$themes"
    cp -a "$REPO_ROOT/samurai/scripts/." "$bin/"
    cp -a "$REPO_ROOT/samurai/themes/." "$themes/"

    find "$bin" -maxdepth 1 -type f -name 'samurai-*' -exec chmod 0755 {} +
    if [[ -d "$BUILD_DIR/config/hooks" ]]; then
        find "$BUILD_DIR/config/hooks" -name '*.hook.chroot' -exec chmod 0755 {} +
    fi
    chmod 0755 "$BUILD_DIR/auto/config"
    log "Synced scripts and themes into config/includes.chroot"
}

run_config() {
    log "Generating live-build configuration"
    (cd "$BUILD_DIR" && bash auto/config)
}

clean_build() {
    require_root
    if [[ ! -d "$BUILD_DIR/.build" && ! -d "$BUILD_DIR/binary" &&
          ! -d "$BUILD_DIR/bootstrap" && ! -d "$BUILD_DIR/chroot" &&
          ! -d "$BUILD_DIR/cache" && ! -d "$BUILD_DIR/config/binary" &&
          ! -d "$BUILD_DIR/config/bootstrap" && ! -d "$BUILD_DIR/config/chroot" ]]; then
        log "Nothing to clean"
        return 0
    fi
    log "Cleaning previous live-build state"
    (cd "$BUILD_DIR" && lb clean --purge)
}

build_iso() {
    log "Building the ISO (this can take 20-60 minutes)"
    (cd "$BUILD_DIR" && lb build 2>&1 | tee build.log)
}

collect_artifacts() {
    local source out name
    local isos=()
    shopt -s nullglob
    isos=("$BUILD_DIR"/live-image-*.hybrid.iso)
    shopt -u nullglob

    ((${#isos[@]} > 0)) || die "Build finished but no live-image-*.hybrid.iso was produced"
    source="${isos[0]}"
    name="samurai-linux-$(date +%Y.%m.%d)-amd64.iso"
    install -d -m 0755 "$REPO_ROOT/dist"
    out="$REPO_ROOT/dist/$name"
    cp -- "$source" "$out"
    (cd "$REPO_ROOT/dist" && sha256sum "$name" > "$name.sha256")

    if [[ -n "${SAMURAI_SIGN_KEY:-}" ]]; then
        command -v gpg >/dev/null 2>&1 || die "SAMURAI_SIGN_KEY is set but gpg is not installed"
        gpg --armor --detach-sign --local-user "$SAMURAI_SIGN_KEY" --output "$out.sig" "$out"
        log "Signed $out"
    else
        warn "SAMURAI_SIGN_KEY is not set; the ISO was not signed"
    fi

    log "ISO:      $out"
    log "Checksum: $out.sha256"
}

main() {
    case "${1:-}" in
        --check)
            check_host
            sync_assets
            run_config
            log "Configuration is valid"
            ;;
        --clean)
            clean_build
            ;;
        --no-clean)
            require_root
            check_host
            sync_assets
            run_config
            build_iso
            collect_artifacts
            ;;
        -h|--help)
            usage
            ;;
        "")
            require_root
            check_host
            sync_assets
            # Configure before cleaning so `lb clean` always has a config to
            # remove (it refuses to run in a fresh checkout), then regenerate.
            run_config
            clean_build
            run_config
            build_iso
            collect_artifacts
            ;;
        *)
            die "Unknown option: $1 (run: bash build/build.sh --help)"
            ;;
    esac
}

main "$@"
