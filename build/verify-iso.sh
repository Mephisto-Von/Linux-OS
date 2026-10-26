#!/usr/bin/env bash
# Verify the contents of a built Samurai Linux ISO before booting or installing it.
# Usage: bash build/verify-iso.sh <iso>
set -euo pipefail

ISO="${1:-}"
TMP_DIR=""

log() { printf '==> %s\n' "$*"; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

cleanup() {
    if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
        rm -rf "$TMP_DIR"
    fi
}
trap cleanup EXIT

if [[ -z "$ISO" ]]; then
    printf 'Usage: %s <iso>\n' "$0" >&2
    exit 1
fi
[[ -f "$ISO" ]] || die "ISO not found: $ISO"

for tool in xorriso unsquashfs; do
    command -v "$tool" >/dev/null 2>&1 || die "$tool is not installed"
done

TMP_DIR=$(mktemp -d)
ROOT="$TMP_DIR/rootfs"
SQUASHFS="$TMP_DIR/filesystem.squashfs"
mkdir -p "$ROOT"

assert_file() {
    local path=$1
    [[ -f "$ROOT/$path" ]] || die "Missing from live rootfs: /$path"
}

assert_contains() {
    local path=$1 pattern=$2
    grep -Eq "$pattern" "$ROOT/$path" || die "/$path does not match: $pattern"
}

log "ISO: $ISO ($(du -h "$ISO" | cut -f1))"

log "Checking ISO boot records"
xorriso -indev "$ISO" -report_el_torito plain >"$TMP_DIR/el-torito.txt" 2>/dev/null
grep -qi 'El Torito boot img' "$TMP_DIR/el-torito.txt" \
    || die "ISO has no El Torito boot record"
grep -qi 'UEFI' "$TMP_DIR/el-torito.txt" \
    || die "ISO has no UEFI boot entry"

log "Extracting live kernel, initramfs, and squashfs"
xorriso -osirrox on -indev "$ISO" \
    -extract /live/vmlinuz "$TMP_DIR/vmlinuz" \
    -extract /live/initrd.img "$TMP_DIR/initrd.img" \
    -extract /live/filesystem.squashfs "$SQUASHFS" >/dev/null
[[ -s "$TMP_DIR/vmlinuz" ]] || die "ISO is missing /live/vmlinuz"
[[ -s "$TMP_DIR/initrd.img" ]] || die "ISO is missing /live/initrd.img"
[[ -s "$SQUASHFS" ]] || die "ISO is missing /live/filesystem.squashfs"

log "Extracting installer files from the live rootfs"
unsquashfs -no-progress -d "$ROOT" "$SQUASHFS" \
    etc/calamares/settings.conf \
    etc/calamares/branding/samurai/branding.desc \
    etc/calamares/branding/samurai/productLogo.png \
    etc/calamares/branding/samurai/productIcon.png \
    etc/calamares/branding/samurai/productWelcome.png \
    etc/calamares/branding/samurai/show.qml \
    usr/bin/calamares \
    usr/bin/calamares-install-debian \
    usr/share/applications/calamares-install-debian.desktop \
    usr/lib/grub/i386-pc/normal.mod \
    usr/lib/grub/x86_64-efi/normal.mod \
    var/lib/dpkg/status >/dev/null

assert_file etc/calamares/settings.conf
assert_file etc/calamares/branding/samurai/branding.desc
assert_file etc/calamares/branding/samurai/productLogo.png
assert_file etc/calamares/branding/samurai/productIcon.png
assert_file etc/calamares/branding/samurai/productWelcome.png
assert_file etc/calamares/branding/samurai/show.qml
assert_file usr/bin/calamares
assert_file usr/bin/calamares-install-debian
assert_file usr/share/applications/calamares-install-debian.desktop
assert_file usr/lib/grub/i386-pc/normal.mod
assert_file usr/lib/grub/x86_64-efi/normal.mod
assert_file var/lib/dpkg/status

log "Checking Calamares branding and desktop entry"
assert_contains etc/calamares/settings.conf '^branding:[[:space:]]*samurai$'
assert_contains etc/calamares/branding/samurai/branding.desc \
    'productName:[[:space:]]+Samurai Linux'
assert_contains usr/share/applications/calamares-install-debian.desktop \
    '^Name=Install Samurai Linux$'
assert_contains usr/share/applications/calamares-install-debian.desktop \
    '^Exec=calamares-install-debian$'

log "Checking installed packages needed by the installer"
assert_contains var/lib/dpkg/status '^Package: calamares$'
assert_contains var/lib/dpkg/status '^Package: calamares-settings-debian$'
assert_contains var/lib/dpkg/status '^Package: grub-pc-bin$'
assert_contains var/lib/dpkg/status '^Package: grub-efi-amd64-bin$'
assert_contains var/lib/dpkg/status '^Package: efibootmgr$'

log "ISO verification passed"
