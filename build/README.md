# Building Samurai Linux

The ISO is assembled with Debian's [`live-build`](https://wiki.debian.org/Projects/DebianLive/). This replaces the hand-written `debootstrap` + `xorriso` steps from the original documentation, which could not produce a bootable image.

## Host requirements

| Resource | Minimum | Recommended |
|---|---|---|
| OS | Debian 13 or Debian 12 | Debian 13 |
| Architecture | x86_64 | x86_64 |
| Free disk | 50 GiB | 100 GiB |
| RAM | 4 GiB | 8 GiB |
| CPU | 2 cores | 4+ cores |

Install the tools on the build host:

```bash
sudo apt-get update
sudo apt-get install -y live-build debootstrap xorriso squashfs-tools gnupg
```

> Build on a real Linux filesystem (ext4/xfs/btrfs). Do not build inside `/mnt/c` or `/mnt/d` under WSL: `chroot` and package maintainer scripts need Unix permissions and device nodes.

## Build

```bash
# From the repository root
sudo bash build/build.sh
```

The script:

1. verifies the host (Linux, x86_64, tools, disk, RAM)
2. copies `samurai/scripts/` and `samurai/themes/` into the live-build include tree
3. runs `auto/config`
4. runs `lb clean --purge` and `lb build`
5. copies the ISO to `dist/` and writes a SHA-256 checksum

Output:

```
dist/samurai-linux-YYYY.MM.DD-amd64.iso
dist/samurai-linux-YYYY.MM.DD-amd64.iso.sha256
```

Useful modes:

```bash
bash build/build.sh --check     # validate host and generate config only
sudo bash build/build.sh --no-clean
sudo bash build/build.sh --clean
```

## Signing

```bash
sudo -E SAMURAI_SIGN_KEY="your-gpg-key-id" bash build/build.sh
```

This creates an armored detached signature (`*.iso.sig`) next to the ISO. Verify it with:

```bash
gpg --verify dist/*.iso.sig dist/*.iso
(cd dist && sha256sum -c ./*.iso.sha256)
```

## Verify the ISO

After a build, verify the live rootfs and installer wiring before booting:

```bash
bash build/verify-iso.sh dist/samurai-linux-*-amd64.iso
```

The script checks the BIOS/UEFI boot records, extracts `/live/vmlinuz`,
`/live/initrd.img`, and `/live/filesystem.squashfs` from the ISO, then verifies
inside the squashfs:

- Calamares and `calamares-settings-debian` are installed
- `branding: samurai` is selected and the Samurai branding assets exist
- the menu entry is named **Install Samurai Linux**
- `grub-pc-bin`, `grub-efi-amd64-bin`, and `efibootmgr` are present for the
  installer's bootloader step

## Boot test

```bash
# Headless: writes serial output and exits after 180 seconds
bash build/qemu-test.sh dist/samurai-linux-*-amd64.iso

# Interactive
bash build/qemu-test.sh dist/samurai-linux-*-amd64.iso --gui
```

The headless run checks the serial log for kernel/systemd boot signs. For a visual check, use `--gui` and confirm that SDDM/KDE Plasma starts.

## What the ISO contains

- Debian 13 (Trixie), KDE Plasma, SDDM, Firefox, common KDE applications
- Developer basics: Git, GCC/Clang via `build-essential`, CMake, Ninja, Python 3
- `samurai-ai`, `samurai-theme`, and `samurai-gaming` in `/usr/local/bin`
- Kuro and Shiro KDE color schemes in `/usr/share/color-schemes`
- Kuro applied for new users; the theme autostart entry restores the last selection
- Calamares installer with Samurai branding, launched from the live desktop or
  the application menu as **Install Samurai Linux**
- GRUB BIOS/UEFI installer packages (`grub-pc-bin`, `grub-efi-amd64-bin`,
  `efibootmgr`, `dosfstools`, `mtools`) so Calamares can install a bootloader
- No Steam, Ollama, or first-boot setup wizard - install Steam/Ollama after
  boot; the installed system inherits the live rootfs

## Customisation

| Path | Purpose |
|---|---|
| `build/auto/config` | `lb config` options (distribution, archive areas, boot parameters) |
| `build/config/package-lists/*.list.chroot` | Packages installed in the chroot |
| `build/config/hooks/normal/*.hook.chroot` | Chroot setup (permissions, color schemes, cleanup) |
| `build/config/includes.chroot/` | Files copied verbatim into the ISO |
| `samurai/scripts/` | Source of truth for the three CLIs |
| `samurai/themes/` | Source of truth for the KDE `.colors` schemes |

The generated copies under `build/config/includes.chroot/usr/local/bin/` and `.../usr/share/samurai/themes/` are ignored by Git; `build.sh` recreates them on every run.

## CI

- `.github/workflows/ci.yml` runs ShellCheck, Python syntax checks, and `tests/smoke.sh` in a `debian:trixie` container.
- `.github/workflows/build-iso-hosted.yml` builds the ISO on an ephemeral GitHub-hosted runner inside a privileged Debian `trixie` container, verifies the ISO contents, then boot-tests it in QEMU. Trigger it manually from the Actions tab; the ISO and checksum are uploaded as artifacts.
- `.github/workflows/build-iso.yml` builds the ISO on a self-hosted runner labelled `samurai-builder`. The runner needs the tools above, 50+ GiB free disk, and `sudo`; use it for signed release builds.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `lb: command not found` | Install `live-build` |
| `Need at least 50 GiB free` | Free disk space or set `SAMURAI_MIN_DISK_GB` (not recommended below 50) |
| `steam-installer` missing after boot | Enable `contrib` in the installed system and run `sudo apt-get update` |
| Scripts have CRLF line endings | Re-clone inside Linux; `.gitattributes` now forces LF |
| Build fails inside WSL `/mnt/*` | Move the repo to the WSL ext4 filesystem |
