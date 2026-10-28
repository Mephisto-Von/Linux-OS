#!/usr/bin/env bash
# Verify the contents of a built Samurai Linux ISO before booting or installing it.
# Usage: bash build/verify-iso.sh <iso>
set -euo pipefail

ISO="${1:-}"
TMP_DIR=""
REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)

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

assert_not_contains() {
    local path=$1 pattern=$2
    if grep -Eq "$pattern" "$ROOT/$path"; then
        die "/$path still matches: $pattern"
    fi
}

assert_file_contains() {
    local path=$1 pattern=$2
    grep -Eq "$pattern" "$path" || die "$path does not match: $pattern"
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
    -extract /live/filesystem.squashfs "$SQUASHFS" \
    -extract /isolinux/isolinux.cfg "$TMP_DIR/isolinux.cfg" \
    -extract /isolinux/menu.cfg "$TMP_DIR/menu.cfg" \
    -extract /isolinux/stdmenu.cfg "$TMP_DIR/stdmenu.cfg" \
    -extract /isolinux/live.cfg "$TMP_DIR/live.cfg" \
    -extract /isolinux/splash.png "$TMP_DIR/isolinux-splash.png" \
    -extract /boot/grub/grub.cfg "$TMP_DIR/grub.cfg" \
    -extract /boot/grub/splash.png "$TMP_DIR/grub-splash.png" \
    -extract /boot/grub/live-theme/theme.txt "$TMP_DIR/grub-theme.txt" >/dev/null
[[ -s "$TMP_DIR/vmlinuz" ]] || die "ISO is missing /live/vmlinuz"
[[ -s "$TMP_DIR/initrd.img" ]] || die "ISO is missing /live/initrd.img"
[[ -s "$SQUASHFS" ]] || die "ISO is missing /live/filesystem.squashfs"

log "Checking the live boot menu auto-boots with a serial console"
grep -Eq '^timeout[[:space:]]+50$' "$TMP_DIR/isolinux.cfg" \
    || die "/isolinux/isolinux.cfg does not auto-boot (timeout is not 5s)"
grep -q 'console=ttyS0,115200n8' "$TMP_DIR/live.cfg" \
    || die "/isolinux/live.cfg does not pass console=ttyS0,115200n8"
grep -q 'console=ttyS0,115200n8' "$TMP_DIR/grub.cfg" \
    || die "/boot/grub/grub.cfg does not pass console=ttyS0,115200n8"

log "Checking Samurai bootloader branding"
assert_file_contains "$TMP_DIR/menu.cfg" '^menu title Samurai Linux 2026\.10$'
assert_file_contains "$TMP_DIR/live.cfg" 'Samurai Linux Live'
assert_file_contains "$TMP_DIR/grub.cfg" 'Samurai Linux Live'
assert_file_contains "$TMP_DIR/stdmenu.cfg" '#b52832ff'
assert_file_contains "$TMP_DIR/grub-theme.txt" '^title-text: ""$'
if grep -Eqi 'Debian' "$TMP_DIR/live.cfg" "$TMP_DIR/grub.cfg"; then
    die "the live boot menus still mention Debian"
fi
cmp -s "$TMP_DIR/isolinux-splash.png" "$REPO_ROOT/build/config/bootloaders/isolinux/splash.png" \
    || die "/isolinux/splash.png is not the Samurai splash"
cmp -s "$TMP_DIR/grub-splash.png" "$REPO_ROOT/build/config/bootloaders/grub-pc/splash.png" \
    || die "/boot/grub/splash.png is not the Samurai splash"

log "Extracting installer files from the live rootfs"
unsquashfs -f -no-progress -d "$ROOT" "$SQUASHFS" \
    etc/calamares/settings.conf \
    etc/calamares/branding/samurai/branding.desc \
    etc/calamares/branding/samurai/productLogo.png \
    etc/calamares/branding/samurai/productIcon.png \
    etc/calamares/branding/samurai/productWelcome.png \
    etc/calamares/branding/samurai/show.qml \
    etc/calamares/branding/samurai/slide1.png \
    usr/bin/calamares \
    usr/bin/calamares-install-debian \
    usr/bin/unsquashfs \
    usr/bin/rsync \
    usr/local/bin/samurai-ai \
    usr/local/bin/samurai-theme \
    usr/local/bin/samurai-gaming \
    usr/share/color-schemes/samurai-kuro.colors \
    usr/share/color-schemes/samurai-shiro.colors \
    usr/share/applications/calamares-install-debian.desktop \
    usr/share/backgrounds/samurai/kuro.jpg \
    usr/share/backgrounds/samurai/shiro.jpg \
    usr/share/samurai/boot/grub-splash.png \
    usr/share/pixmaps/samurai-linux.png \
    usr/lib/grub/i386-pc/normal.mod \
    usr/lib/grub/x86_64-efi/normal.mod \
    etc/os-release \
    etc/issue \
    etc/issue.net \
    etc/lsb-release \
    etc/motd \
    etc/default/grub \
    var/lib/dpkg/status >/dev/null

assert_file etc/calamares/settings.conf
assert_file etc/calamares/branding/samurai/branding.desc
assert_file etc/calamares/branding/samurai/productLogo.png
assert_file etc/calamares/branding/samurai/productIcon.png
assert_file etc/calamares/branding/samurai/productWelcome.png
assert_file etc/calamares/branding/samurai/show.qml
assert_file etc/calamares/branding/samurai/slide1.png
assert_file usr/bin/calamares
assert_file usr/bin/calamares-install-debian
assert_file usr/bin/unsquashfs
assert_file usr/bin/rsync
assert_file usr/local/bin/samurai-ai
assert_file usr/local/bin/samurai-theme
assert_file usr/local/bin/samurai-gaming
assert_file usr/share/color-schemes/samurai-kuro.colors
assert_file usr/share/color-schemes/samurai-shiro.colors
assert_file usr/share/applications/calamares-install-debian.desktop
assert_file usr/share/backgrounds/samurai/kuro.jpg
assert_file usr/share/backgrounds/samurai/shiro.jpg
assert_file usr/share/samurai/boot/grub-splash.png
assert_file usr/share/pixmaps/samurai-linux.png
assert_file usr/lib/grub/i386-pc/normal.mod
assert_file usr/lib/grub/x86_64-efi/normal.mod
assert_file etc/os-release
assert_file etc/issue
assert_file etc/issue.net
assert_file etc/lsb-release
assert_file etc/motd
assert_file etc/default/grub
assert_file var/lib/dpkg/status

log "Checking Calamares branding and desktop entry"
assert_contains etc/calamares/settings.conf '^branding:[[:space:]]*samurai$'
assert_contains etc/calamares/branding/samurai/branding.desc \
    'productName:[[:space:]]+Samurai Linux'
assert_contains usr/share/applications/calamares-install-debian.desktop \
    '^Name=Install Samurai Linux$'
assert_contains usr/share/applications/calamares-install-debian.desktop \
    '^Exec=calamares-install-debian$'

log "Checking distribution branding"
assert_contains etc/os-release '^NAME="Samurai Linux"$'
assert_contains etc/os-release '^ID=samurai$'
assert_contains etc/os-release '^PRETTY_NAME="Samurai Linux 2026\.10"$'
assert_contains etc/os-release '^ID_LIKE=debian$'
assert_contains etc/issue 'Samurai Linux 2026\.10'
assert_contains etc/issue.net 'Samurai Linux 2026\.10'
assert_contains etc/lsb-release '^DISTRIB_ID=Samurai$'
assert_contains etc/motd 'Welcome to Samurai Linux'
assert_not_contains etc/os-release 'Debian GNU/Linux'
assert_not_contains etc/issue 'Debian GNU/Linux'
assert_not_contains etc/issue.net 'Debian GNU/Linux'
assert_contains etc/default/grub '^GRUB_DISTRIBUTOR="Samurai Linux"$'
assert_contains etc/default/grub '^GRUB_BACKGROUND="/usr/share/samurai/boot/grub-splash.png"$'
assert_contains etc/default/grub 'console=ttyS0,115200n8'
cmp -s "$ROOT/usr/share/samurai/boot/grub-splash.png" \
    "$REPO_ROOT/build/config/includes.chroot/usr/share/samurai/boot/grub-splash.png" \
    || die "the installed GRUB splash is not the Samurai splash"

log "Checking desktop wallpapers"
for wallpaper in kuro.jpg shiro.jpg; do
    cmp -s "$ROOT/usr/share/backgrounds/samurai/$wallpaper" \
        "$REPO_ROOT/build/config/includes.chroot/usr/share/backgrounds/samurai/$wallpaper" \
        || die "/usr/share/backgrounds/samurai/$wallpaper is not the Samurai wallpaper"
done

log "Checking that the live rootfs can run update-grub"
# Calamares' calamares-bootloader-config helper ends with update-grub, which
# writes /boot/grub/grub.cfg. The live image never installs GRUB to a disk, so
# the directory has to ship in the image or the installer fails offline.
unsquashfs -l "$SQUASHFS" boot/grub >/dev/null 2>&1 \
    || die "the live rootfs has no /boot/grub; Calamares could not write grub.cfg"

log "Checking installed packages needed by the installer"
assert_contains var/lib/dpkg/status '^Package: calamares$'
assert_contains var/lib/dpkg/status '^Package: calamares-settings-debian$'
assert_contains var/lib/dpkg/status '^Package: grub-pc-bin$'
assert_contains var/lib/dpkg/status '^Package: grub-efi-amd64-bin$'
assert_contains var/lib/dpkg/status '^Package: efibootmgr$'
assert_contains var/lib/dpkg/status '^Package: squashfs-tools$'
assert_contains var/lib/dpkg/status '^Package: rsync$'
assert_contains var/lib/dpkg/status '^Package: cryptsetup$'

log "ISO verification passed"
